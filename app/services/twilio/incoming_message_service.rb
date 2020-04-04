class Twilio::IncomingMessageService
  pattr_initialize [:params!]

  def perform
    set_contact
    set_conversation
    @conversation.messages.create(
      content: params[:body],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      contact_id: @contact.id,
      source_id: params[:SmsSid]
    )
  end

  private

  def twilio_inbox
    @twilio_inbox ||= ::Channel::TwilioSms.find_by!(
      account_sid: params[:AccountSid],
      phone_number: params[:To]
    )
  end

  def inbox
    @inbox ||= twilio_inbox.inbox
  end

  def account
    @account ||= inbox.account
  end

  def set_contact
    @contact, @contact_inbox = ::ContactBuider.new(
      source_id: permitted_params[:From],
      inbox: inbox,
      contact_attributes: contact_attributes
    )
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: additional_attributes
    }
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.first
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: permitted_params[:From],
      phone_number: permitted_params[:From],
      contact_attributes: additional_attributes
    }
  end

  def additional_attributes
    {
      from_zip_code: params[:FromZip],
      from_country: params[:FromCountry],
      from_state: params[:FromState]
    }
  end
end
