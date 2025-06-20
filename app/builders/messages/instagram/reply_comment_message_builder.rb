class Messages::Instagram::ReplyCommentMessageBuilder
  def initialize(message, inbox)
    @message = message
    @inbox = inbox
    @access_token = inbox.channel.access_token
  end

  def perform
    return unless @inbox.auto_reply_post_comments_enabled

    url = "#{base_uri}/#{@message[:id]}/replies?message=#{reply_content}&hide=false"
    HTTParty.post(url, query: { access_token: @access_token })
  end

  private

  def reply_content
    @inbox.auto_reply_post_comments_message.gsub('{{contact_mention}}', "@#{@message.dig(:from, :username)}")
  end

  def base_uri
    "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"
  end
end
