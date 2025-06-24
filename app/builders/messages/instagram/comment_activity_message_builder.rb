class Messages::Instagram::CommentActivityMessageBuilder
  def initialize(message, conversation, inbox)
    @message = message
    @conversation = conversation
    @inbox = inbox
  end

  def perform
    ::Conversations::ActivityMessageJob.new.perform(conversation, activity_message_params)
  end

  private

  attr_reader :message, :conversation, :inbox

  def activity_message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: activity_content,
      content_attributes: {
        activity_type: 'post',
        link: post['permalink'],
        post: {
          content: post['caption'],
          attachments: post_attachments,
          created_time: Time.parse(post['timestamp']).strftime('%d/%m/%y %H:%M')
        }
      }
    }
  end

  def activity_content
    "#{message.dig(:from, :username)} commented on a post."
  end

  def post
    base_uri = "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}/#{message.dig(:media, :id)}"
    @post ||= HTTParty.get(base_uri, query: {
                             fields: 'caption,timestamp,media_type,media_url,permalink,children{media_type,media_url}',
                             access_token: inbox.channel.access_token
                           })
  rescue Koala::Facebook::AuthenticationError => e
    Rails.logger.warn("Facebook authentication error for inbox: #{inbox.id} with error: #{e.message}")
    Rails.logger.error e
    inbox.channel.authorization_error!
    raise
  rescue Koala::Facebook::ClientError => e
    # OAuthException, code: 100, error_subcode: 2018218, message: (#100) No profile available for this user
    if e.message.include?('2018218')
      Rails.logger.warn e
    else
      ChatwootExceptionTracker.new(e, account: inbox.account).capture_exception
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: inbox.account).capture_exception
  end

  def post_attachments
    case post['media_type']
    when 'IMAGE'
      [{ type: 'image', url: post['media_url'] }.deep_stringify_keys]
    when 'VIDEO'
      [{ type: 'video', url: post['media_url'] }.deep_stringify_keys]
    when 'CAROUSEL_ALBUM'
      post['children']['data'].map do |child|
        { type: child['media_type'].downcase, url: child['media_url'] }.deep_stringify_keys
      end
    else
      []
    end
  end
end
