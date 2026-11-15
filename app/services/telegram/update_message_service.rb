# Find the various telegram payload samples here: https://core.telegram.org/bots/webhooks#testing-your-bot-with-updates
# https://core.telegram.org/bots/api#available-types

class Telegram::UpdateMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    transform_business_message!
    find_contact_inbox
    return if @contact_inbox.contact.blocked? && !business_message_outgoing?

    find_conversation
    find_message
    update_message
  rescue StandardError => e
    Rails.logger.error "Error while processing telegram message update #{e.message}"
  end

  private

  def business_message_outgoing?
    return false if params[:edited_business_message].blank?

    edited_msg = params[:edited_message]
    return false if edited_msg.blank? || edited_msg[:chat].blank? || edited_msg[:from].blank?

    edited_msg[:chat][:id].to_s != edited_msg[:from][:id].to_s
  end

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

    if edited_message[:text].present?
      @message.update!(content: edited_message[:text])
    elsif edited_message[:caption].present?
      @message.update!(content: edited_message[:caption])
    end
  end

  def transform_business_message!
    params[:edited_message] = params[:edited_business_message] if params[:edited_business_message].present?
  end
end
