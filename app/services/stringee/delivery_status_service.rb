class Stringee::DeliveryStatusService
  pattr_initialize [:inbox!, :params!]

  def perform
    build_message
    return unless @message

    @conversation = @message.conversation
    set_assignee

    @message.content = message_content
    @message.additional_attributes = message_additional_attributes
    @message.save!
  end

  private

  def build_message
    @message = inbox.messages.find_by(source_id: params[:call_id])
    return if @message.present?

    Stringee::CallingEventsService.new(inbox: inbox, params: params).perform
    @message = inbox.messages.find_by(source_id: source_id)
  end

  def set_assignee
    stringee_user_id = incoming? ? params[:to][:number] : params[:request_from_user_id]
    agent = User.where('email LIKE ?', "#{stringee_user_id}@%").first
    return unless agent

    if @conversation.assignee_id.blank?
      @conversation.assignee = agent
      @conversation.save!
      if initial_conversation?
        contact = @conversation.contact
        contact.assignee = agent
        contact.save!
      end
    end

    ::AutoAssignment::StringeeAssignmentService.new(inbox: @conversation.inbox).pop_push_to_right_queue(agent.id) if inbox.channel.from_list?
  end

  def initial_conversation?
    contact = @conversation.contact
    @conversation.id == contact.initial_conversation&.id
  end

  def message_content
    if missed_call?
      I18n.t('conversations.messages.stringee.missed_call', duration: params[:duration].to_s)
    else
      call_type = incoming? ? 'incoming_call' : 'outgoing_call'
      formatted_duration = format_duration(params[:answerDuration].to_i)
      I18n.t("conversations.messages.stringee.#{call_type}", answer_duration: formatted_duration)
    end
  end

  def format_duration(seconds)
    minutes = seconds / 60
    remaining_seconds = seconds % 60
    minutes.zero? ? "#{remaining_seconds} giây" : "#{minutes} phút #{remaining_seconds} giây"
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
