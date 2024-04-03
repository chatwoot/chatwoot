class Stringee::CallEventsService
  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    set_conversation
    set_assignee
    read_message

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
      source_id: incoming? ? params[:from][:alias] : params[:to][:alias],
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_assignee
    stringee_user_id = incoming? ? params[:to][:number] : params[:request_from_user_id]
    agent = User.from_email(stringee_user_id.sub('_', '@'))
    return unless agent

    @conversation.assignee_id = agent.id
    @conversation.save!
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
    if missed_call?
      I18n.t('conversations.messages.stringee.missed_call', duration: params[:duration].to_s)
    else
      call_type = incoming? ? 'incoming_call' : 'outgoing_call'
      I18n.t("conversations.messages.stringee.#{call_type}", answer_duration: params[:answerDuration].to_s)
    end
  end

  def message_additional_attributes
    {
      timestamp_ms: params[:timestamp_ms],
      callCreatedReason: params[:callCreatedReason],
      endCallCause: params[:endCallCause],
      duration: params[:duration],
      answerDuration: params[:answerDuration]
    }
  end

  def message_params
    {
      content: message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: incoming? ? :incoming : :outgoing,
      sender: @contact,
      source_id: params[:call_id],
      additional_attributes: message_additional_attributes
    }
  end

  def read_message
    return if incoming? && missed_call?

    last_seen_at = DateTime.now.utc + 10.seconds
    @conversation.agent_last_seen_at = last_seen_at
    @conversation.assignee_last_seen_at = last_seen_at
    @conversation.save!
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

  def missed_call?
    params[:endCallCause] != 'USER_END_CALL' || params[:answeredTime].zero?
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
