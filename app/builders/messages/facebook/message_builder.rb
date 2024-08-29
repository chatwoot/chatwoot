# This class creates both outgoing messages from chatwoot and echo outgoing messages based on the flag `outgoing_echo`
# Assumptions
# 1. Incase of an outgoing message which is echo, source_id will NOT be nil,
#    based on this we are showing "not sent from chatwoot" message in frontend
#    Hence there is no need to set user_id in message for outgoing echo messages.

class Messages::Facebook::MessageBuilder < Messages::Messenger::MessageBuilder
  attr_reader :response

  def initialize(response, inbox, outgoing_echo: false)
    super()
    @response = response
    @inbox = inbox
    @outgoing_echo = outgoing_echo
    @sender_id = (@outgoing_echo ? @response.recipient_id : @response.sender_id)
    @message_type = (@outgoing_echo ? :outgoing : :incoming)
    @attachments = (@response.attachments || [])
  end

  def perform
    # This channel might require reauthorization, may be owner might have changed the fb password
    return if @inbox.channel.reauthorization_required?

    ActiveRecord::Base.transaction do
      build_contact_inbox
      build_message
    end
  rescue Koala::Facebook::AuthenticationError => e
    Rails.logger.warn("Facebook authentication error for inbox: #{@inbox.id} with error: #{e.message}")
    Rails.logger.error e
    @inbox.channel.authorization_error!
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    true
  end

  def contact
    @contact ||= @inbox.contact_inboxes.find_by(source_id: @sender_id)&.contact
  end

  private

  def build_contact_inbox
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: @sender_id,
      inbox: @inbox,
      contact_attributes: contact_params
    ).perform
  end

  def build_message
    @message = conversation.messages.create!(message_params)

    @attachments.each do |attachment|
      process_attachment(attachment)
    end
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

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def build_conversation
    previous_messages = fetch_previous_messages
    new_conversation = Conversation.create!(conversation_params.merge(
                                              contact_inbox_id: @contact_inbox.id
                                            ))

    previous_messages.each do |message_attributes|
      new_message = new_conversation.messages.create!(message_attributes.except('id'))

      # duplicate the attachments if present
      previous_message_attachments = Attachment.where(message_id: message_attributes['id'])

      previous_message_attachments.each do |attachment|
        attachment_active_storage = ActiveStorage::Attachment.where(record_id: attachment.id)

        if attachment_active_storage.exists?
          attachment_active_storage.each do |active_storage_attachment|
            # finding the blob for that active storage attachment
            original_blob = ActiveStorage::Blob.find_by(id: active_storage_attachment.blob_id)

            next unless original_blob

            new_attachment = new_message.attachments.create!(attachment.attributes.except('id', 'message_id'))

            ActiveStorage::Attachment.create!(
              name: active_storage_attachment.name,
              record_type: active_storage_attachment.record_type,
              record_id: new_attachment.id,
              blob_id: original_blob.id,
              created_at: Time.zone.now
            )
          end
        else
          new_message.attachments.create!(attachment.attributes.except('id', 'message_id'))
        end
      end
    end

    new_conversation.messages.create!(private_message_params("Conversation with #{contact.name.capitalize} started",
                                                             new_conversation))
    new_conversation
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def private_message_params(content, new_conversation)
    { account_id: new_conversation.account_id, inbox_id: new_conversation.inbox_id, message_type: :outgoing, content: content, private: true }
  end

  def location_params(attachment)
    lat = attachment['payload']['coordinates']['lat']
    long = attachment['payload']['coordinates']['long']
    {
      external_url: attachment['url'],
      coordinates_lat: lat,
      coordinates_long: long,
      fallback_title: attachment['title']
    }
  end

  def fallback_params(attachment)
    {
      fallback_title: attachment['title'],
      external_url: attachment['url']
    }
  end

  def fetch_previous_messages
    # apparantly the first one seems to be the newly created one in this case
    previous_conversation = Conversation.where(conversation_params).order(created_at: :desc).first

    return [] if previous_conversation.blank?

    previous_conversation.messages
                         .reject { |msg| msg.private && msg.content.include?('Conversation with') }
                         .map do |message|
      message.attributes.except('conversation_id').merge(
        additional_attributes: (message.additional_attributes || {}).merge(ignore_automation_rules: true, disable_notifications: true)
      )
    end
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
      source_id: response.identifier,
      content_attributes: {
        in_reply_to_external_id: response.in_reply_to_external_id
      },
      sender: @outgoing_echo ? nil : @contact_inbox.contact
    }
  end

  def process_contact_params_result(result)
    full_name = if result['first_name'] || result['last_name']
                  "#{result['first_name'] || 'John'} #{result['last_name'] || 'Doe'}"
                elsif result['name']
                  result['name']
                else
                  'John Doe'
                end
    {
      name: full_name,
      account_id: @inbox.account_id,
      avatar_url: result['profile_pic']
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
