class Stringee::DeliveryStatusService
  pattr_initialize [:inbox!, :params!]

  def perform
    @message = inbox.messages.find_by(source_id: params[:call_id])
    return unless @message

    @conversation = @message.conversation
    set_assignee

    @message.content = message_content
    @message.additional_attributes = message_additional_attributes
    @message.save!
  end

  private

  def set_assignee
    stringee_user_id = incoming? ? params[:to][:number] : params[:request_from_user_id]
    agent = User.from_email(stringee_user_id.sub('_', '@'))
    return unless agent

    @conversation.assignee_id = agent.id
    @conversation.save!
    ::AutoAssignment::StringeeAssignmentService.new(inbox: @conversation.inbox).pop_push_to_right_queue(agent.id)
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

  def incoming?
    params[:callCreatedReason] == 'EXTERNAL_CALL_IN'
  end

  def missed_call?
    params[:endCallCause] != 'USER_END_CALL' || params[:answerDuration].zero?
  end
end
