# Find the various telegram payload samples here: https://core.telegram.org/bots/webhooks#testing-your-bot-with-updates
# https://core.telegram.org/bots/api#available-types

class Telegram::UpdateMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    transform_business_message!
    find_contact_inbox
    find_conversation
    find_message
    update_message
  rescue StandardError => e
    Rails.logger.error "Error while processing telegram message update #{e.message}"
  end

  private

  def find_contact_inbox
    @contact_inbox = inbox.contact_inboxes.find_by!(source_id: params[:edited_message][:chat][:id])
  end

  def find_conversation
    @conversation = @contact_inbox.conversations.last
  end

  def find_message
    @message = @conversation.messages.find_by(source_id: params[:edited_message][:message_id])
  end

  def update_message
    edited_message = params[:edited_message]
    new_content = edited_message[:text].presence || edited_message[:caption].presence
    return if new_content.blank?
    return if new_content == @message.content

    track_previous_content!
    @message.update!(content: new_content)
  end

  def track_previous_content!
    previous_contents = Array(@message.content_attributes[:previous_contents])
    previous_contents << {
      content: @message.content,
      edited_at: Time.current.to_i
    }
    @message.content_attributes = @message.content_attributes.merge(previous_contents: previous_contents)
  end

  def transform_business_message!
    params[:edited_message] = params[:edited_business_message] if params[:edited_business_message].present?
  end
end
