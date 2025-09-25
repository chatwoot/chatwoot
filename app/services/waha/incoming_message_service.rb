class Waha::IncomingMessageService
  include Waha::ParamHelpers

  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    set_conversation

    @message = @conversation.messages.build(
      content: message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: message_id.to_s,
      additional_attributes: {
        name: sender_full_name,
        phone_number: formatted_phone_number,
        channel: 'WhatsappUnofficial'
      }
    )

    @message.save!
  end

  private

  def set_contact
    contact_inbox = ContactInboxWithContactBuilder.new(
      source_id: phone_number,
      inbox: inbox,
      contact_attributes: {
        name: sender_full_name,
        phone_number: formatted_phone_number
      }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_conversation
    @conversation = @contact.conversations.where(inbox: inbox).last

    return unless @conversation.blank? || @conversation.resolved?

    @conversation = Conversation.create!(
      account_id: @contact.account_id,
      inbox: inbox,
      contact: @contact,
      contact_inbox: @contact_inbox
    )
  end
end
