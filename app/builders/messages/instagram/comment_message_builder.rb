class Messages::Instagram::CommentMessageBuilder < Messages::Instagram::BaseMessageBuilder
  def initialize(message, inbox)
    @message = message
    @inbox = inbox
    @contact_inbox = inbox.contact_inboxes.where(source_id: sender_id).last
  end

  def perform
    return if @inbox.channel.reauthorization_required?
    return if message_existed?

    ActiveRecord::Base.transaction do
      build_activity_message
      build_comment_message
    end
  end

  private

  def sender_id
    @message.dig(:from, :id)
  end

  def post_url
    base_uri = "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"
    response = HTTParty.get("#{base_uri}/#{@message.dig(:media, :id)}?fields=permalink&access_token=#{@inbox.channel.access_token}")
    response['permalink']
  rescue Koala::Facebook::AuthenticationError => e
    Rails.logger.warn("Facebook authentication error for inbox: #{@inbox.id} with error: #{e.message}")
    Rails.logger.error e
    @inbox.channel.authorization_error!
    raise
  rescue Koala::Facebook::ClientError => e
    # OAuthException, code: 100, error_subcode: 2018218, message: (#100) No profile available for this user
    if e.message.include?('2018218')
      Rails.logger.warn e
    else
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception unless @outgoing_echo
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
  end

  def message_existed?
    Message.find_by(source_id: @message[:id], message_type: :incoming).present?
  end

  def build_activity_message
    ::Conversations::ActivityMessageJob.new.perform(conversation, activity_message_params)
  end

  def build_comment_message
    @message = conversation.messages.create!(message_params)
  end

  def activity_message_params
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity, content: activity_content }
  end

  def activity_content
    "Customer commented on <a href='#{post_url}' class='underline text-n-blue-text'>post</a>"
  end

  def message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :incoming,
      content: @message[:text],
      source_id: @message[:id],
      sender: @contact_inbox.contact
    }
  end
end
