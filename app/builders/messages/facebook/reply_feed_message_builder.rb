class Messages::Facebook::ReplyFeedMessageBuilder
  def initialize(response, page)
    @response = response
    @inbox = page.inbox
    @page_access_token = page.page_access_token
  end

  def perform
    return unless @inbox.auto_reply_post_comments_enabled

    k = Koala::Facebook::API.new(@page_access_token)
    k.put_comment(comment_id, reply_content)
  end

  private

  attr_reader :response, :page

  def user_id
    response.sender_id
  end

  def comment_id
    response.comment_id
  end

  def reply_content
    @inbox.auto_reply_post_comments_message.gsub('{{contact_mention}}', "@[#{user_id}]")
  end
end
