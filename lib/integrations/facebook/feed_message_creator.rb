# frozen_string_literal: true

class Integrations::Facebook::FeedMessageCreator
  def initialize(response)
    @response = response
  end

  def perform
    # Skip processing if the response is a removal event
    return if response.verb == 'remove'

    case response.item_type
    when 'comment'
      create_comment_message
    end
  end

  private

  attr_reader :response

  def create_comment_message
    page = Channel::FacebookPage.find_by!(page_id: response.page_id)
    return if page_reply_message?

    Messages::Facebook::FeedMessageBuilder.new(response, page.inbox).perform
    Messages::Facebook::ReplyFeedMessageBuilder.new(response, page).perform
  end

  def page_reply_message?
    response.sender_id == response.page_id
  end
end
