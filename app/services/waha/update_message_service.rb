class Waha::UpdateMessageService
  include Waha::ParamHelpers

  pattr_initialize [:inbox!, :params!]

  def perform
    find_contact_inbox
    find_conversation
    find_message
    update_message
  rescue StandardError => e
    Rails.logger.error "Error while processing waha message update #{e.message}"
  end

  private

  def find_contact_inbox
    @contact_inbox = inbox.contact_inboxes.find_by!(source_id: phone_number)
  end

  def find_conversation
    @conversation = @contact_inbox.conversations.last
  end

  def find_message
    @message = @conversation.messages.find_by(source_id: params[:message][:id])
  end

  def update_message
    return if params[:edited_text].blank?

    @message.update!(content: params[:edited_text])
  end
end
