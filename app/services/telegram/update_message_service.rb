# Find the various telegram payload samples here: https://core.telegram.org/bots/webhooks#testing-your-bot-with-updates
# https://core.telegram.org/bots/api#available-types

class Telegram::UpdateMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
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
    @message.update!(content: params[:edited_message][:text])
  end
end
