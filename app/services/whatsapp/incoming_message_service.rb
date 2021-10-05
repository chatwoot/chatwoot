# Find the various telegram payload samples here: https://core.telegram.org/bots/webhooks#testing-your-bot-with-updates
# https://core.telegram.org/bots/api#available-types

class Whatsapp::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    return unless @contact

    set_conversation

    return if params[:messages].blank?

    @message = @conversation.messages.create(
      content: params[:messages].first.dig(:text, :body),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:messages].first[:id].to_s
    )
    @message.save!
  end

  private

  def account
    @account ||= inbox.account
  end

  def set_contact
    contact_params = params[:contacts]&.first
    return if contact_params.blank?

    contact_inbox = ::ContactBuilder.new(
      source_id: contact_params[:wa_id],
      inbox: inbox,
      contact_attributes: { name: contact_params.dig(:profile, :name), phone_number: "+#{params[:messages].first[:from]}" }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.last
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end
end
