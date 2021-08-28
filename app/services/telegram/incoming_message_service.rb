class Telegram::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    set_conversation
    @message = @conversation.messages.create(
      content: params[:message][:text],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: "#{params[:message][:message_id]}"
    )
    @message.save!
  end

  private

  def account
    @account ||= inbox.account
  end

  def set_contact
    contact_inbox = ::ContactBuilder.new(
      source_id: params[:message][:from][:id],
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: conversation_additional_attributes
    }
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.first
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: "#{params[:message][:from][:first_name]} #{params[:message][:from][:last_name]}" ,
      additional_attributes: additional_attributes
    }
  end

  def additional_attributes
    {
      username: params[:message][:from][:username],
      language_code: params[:message][:from][:language_code],
    }
  end

  def conversation_additional_attributes
    {
      chat_id: params[:message][:chat][:id],
    }
  end
end
