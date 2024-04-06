class Stringee::CallingEventsService
  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    set_conversation
    @message = @conversation.messages.create!(message_params)
    @message.save!
  end

  private

  def account
    @account ||= @inbox.account
  end

  def channel
    @channel ||= @inbox.channel
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: incoming? ? params[:from][:number] : params[:to][:number],
      inbox: @inbox,
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
      contact_inbox_id: @contact_inbox.id
    }
  end

  def message_content
    call_type = incoming? ? 'incoming_calling' : 'outgoing_calling'
    I18n.t("conversations.messages.stringee.#{call_type}")
  end

  def message_params
    {
      content: message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: incoming? ? :incoming : :outgoing,
      sender: @contact,
      source_id: params[:call_id]
    }
  end

  def set_conversation
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations.where
                                    .not(status: :resolved).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def incoming?
    params[:callCreatedReason] == 'EXTERNAL_CALL_IN'
  end

  def contact_attributes
    number = incoming? ? params[:from][:number] : params[:to][:number]
    number.prepend('+') unless number.start_with?('+')
    {
      name: number,
      phone_number: number
    }
  end
end
