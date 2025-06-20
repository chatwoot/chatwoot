class Messages::Facebook::FeedActivityMessageBuilder < Messages::Messenger::MessageBuilder
  def initialize(response, conversation, inbox)
    @response = response
    @conversation = conversation
    @page_access_token = inbox.channel.page_access_token
  end

  def perform
    @message = ::Conversations::ActivityMessageJob.new.perform(conversation, activity_message_params)
  end

  private

  attr_reader :response, :conversation, :inbox

  def activity_message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: activity_content,
      content_attributes: {
        activity_type: 'post',
        post: {
          content: post['message'],
          attachments: post_attachments,
          created_time: Time.parse(post['created_time']).strftime('%d/%m/%y %H:%M')
        }
      }
    }
  end

  def activity_content
    "<span class='font-semibold text-n-blue-text'>#{response.sender_name}</span> commented on a post. <a href='#{response.post_url}' class='underline text-n-blue-text'>View external post</a>"
  end

  def post
    k = Koala::Facebook::API.new(@page_access_token)
    @post ||= k.get_object(response.post_id, fields: %w[message attachments created_time]) || {}
  rescue Koala::Facebook::AuthenticationError => e
    Rails.logger.warn("Facebook authentication error for inbox: #{@inbox.id} with error: #{e.message}")
    Rails.logger.error e
    @inbox.channel.authorization_error!
    raise
  rescue Koala::Facebook::ClientError, StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
  end

  def post_attachments
    post['attachments']['data'].map do |attachment|
      attachment_payload = attachment['media']
      if attachment_payload['source'].present?
        { 'type': 'video', url: attachment_payload['source'] }.deep_stringify_keys
      else
        { 'type': 'image', url: attachment_payload['image']['src'] }.deep_stringify_keys
      end
    end
  end
end
