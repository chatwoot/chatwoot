class Stringee::CallEventsService

  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    set_conversation
    set_assignee
    @message = @conversation.messages.create!(message_params)
    Rails.logger.info('Message created')
    @message.save!
    read_message
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
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_assignee
    stringee_user_id = params[:request_from_user_id]
    agent = User.find_by(email: stringee_user_id.sub('_', '@'))
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
    content = ''
    if is_missed_call
      content = 'Cuộc gọi nhỡ ' +
      'trong ' + params[:duration] + ' giây.'
    else
      content = 'Cuộc gọi ' +
        is_incomming ? 'đến ' : 'đi ' +
        'trong ' + params[:answerDuration] + ' giây.'
    end
    content
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
      message_type: is_incomming ? :incoming : :outgoing,
      sender: @contact,
      source_id: params[:call_id],
      additional_attributes: message_additional_attributes
    }
  end

  def read_message
    return if is_incomming && is_missed_call

    last_seen_at = @message.created_at + 1.second
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

  def is_incomming
    params[:callCreatedReason] == 'EXTERNAL_CALL_IN'
  end

  def is_missed_call
    params[:endCallCause] != 'USER_END_CALL'
  end

  def contact_attributes
    {
      phone_number: is_incomming ? params[:from][:number] : params[:to][:number]
    }
  end
end
