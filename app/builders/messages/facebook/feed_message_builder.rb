# This class handle all feed activities including:
# 1. Comment on page posts or ad posts

class Messages::Facebook::FeedMessageBuilder < Messages::Messenger::MessageBuilder
  def initialize(response, inbox)
    @response = response
    @inbox = inbox
    @sender_id = response.sender_id
    @attachment = response.attachment
    @message_type = :incoming
  end

  def perform
    # This channel might require reauthorization, may be owner might have changed the fb password.
    # Skip creating new message if the auto reply service failed to create a message
    return if @inbox.channel.reauthorization_required?
    return if skipped?

    ActiveRecord::Base.transaction do
      build_contact_inbox
      build_activity_message
      build_feed_message
    end
  rescue Koala::Facebook::AuthenticationError => e
    Rails.logger.warn("Facebook authentication error for inbox: #{@inbox.id} with error: #{e.message}")
    Rails.logger.error e
    @inbox.channel.authorization_error!
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    true
  end

  private

  attr_reader :response

  def skipped?
    Message.find_by(source_id: response.comment_id, message_type: :incoming).present?
  end

  def build_activity_message
    ::Conversations::ActivityMessageJob.new.perform(conversation, activity_message_params)
  end

  # This method is used to build the message for feed activities like comments on posts.
  # Comments only support single attachment at the time of implementation.
  def build_feed_message
    @message = conversation.messages.create!(message_params)

    process_attachment(@attachment) if @attachment.present?
  end

  def conversation
    @conversation ||= set_conversation_based_on_inbox_config
  end

  def set_conversation_based_on_inbox_config
    if @inbox.lock_to_single_conversation
      Conversation.where(conversation_params).order(created_at: :desc).first || build_conversation
    else
      find_or_build_for_multiple_conversations
    end
  end

  def find_or_build_for_multiple_conversations
    # If lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    last_conversation = Conversation.where(conversation_params).where.not(status: :resolved).order(created_at: :desc).first
    return build_conversation if last_conversation.nil?

    last_conversation
  end

  def build_conversation
    Conversation.create!(conversation_params.merge(
                           contact_inbox_id: @contact_inbox.id
                         ))
  end

  def build_contact_inbox
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: @sender_id,
      inbox: @inbox,
      contact_attributes: contact_params
    ).perform
  end

  def process_contact_params_result(result)
    {
      name: "#{result['first_name'] || 'John'} #{result['last_name'] || 'Doe'}",
      account_id: @inbox.account_id,
      avatar_url: result['profile_pic'],
      identifier: @sender_id
    }
  end

  def activity_message_params
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity, content: activity_content }
  end

  def activity_content
    "Customer commented on <a href='#{response.post_url}' class='underline text-n-blue-text'>post</a>"
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact_inbox.contact_id
    }
  end

  def message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: @message_type,
      content: response.content,
      source_id: response.comment_id,
      sender: @contact_inbox.contact
    }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def contact_params
    begin
      k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?
      result = k.get_object(@sender_id) || {}
    rescue Koala::Facebook::AuthenticationError => e
      Rails.logger.warn("Facebook authentication error for inbox: #{@inbox.id} with error: #{e.message}")
      Rails.logger.error e
      @inbox.channel.authorization_error!
      raise
    rescue Koala::Facebook::ClientError => e
      result = {}
      # OAuthException, code: 100, error_subcode: 2018218, message: (#100) No profile available for this user
      # We don't need to capture this error as we don't care about contact params in case of echo messages
      if e.message.include?('2018218')
        Rails.logger.warn e
      else
        ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception unless @outgoing_echo
      end
    rescue StandardError => e
      result = {}
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    end
    process_contact_params_result(result)
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
