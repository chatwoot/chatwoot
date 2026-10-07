class V2::Reports::DrilldownRecordSerializer
  MESSAGE_EVENT_METRICS = %w[avg_first_response_time reply_time].freeze

  attr_reader :account, :metric, :use_business_hours, :records

  def initialize(account, metric, use_business_hours, records = [])
    @account = account
    @metric = metric
    @use_business_hours = use_business_hours
    @records = records
  end

  def serialize(record)
    return serialize_message(record) if record.is_a?(Message)
    return serialize_conversation_event(record) if record.is_a?(ReportingEvent)

    serialize_conversation(record)
  end

  private

  def serialize_message(message, metric_value: nil, occurred_at: nil)
    {
      record_type: 'message',
      conversation: conversation_attributes(message.conversation),
      message: message_attributes(message),
      metric_value: metric_value,
      occurred_at: (occurred_at || message.created_at).to_i
    }
  end

  def serialize_conversation_event(event)
    inferred_message = inferred_message_for(event)
    if inferred_message.present?
      return serialize_message(
        inferred_message,
        metric_value: event_metric_value(event),
        occurred_at: event_timestamp(event)
      )
    end

    serialize_conversation(
      event.conversation,
      metric_value: event_metric_value(event),
      occurred_at: event_timestamp(event),
      event_name: event.name
    )
  end

  def serialize_conversation(conversation, metric_value: nil, occurred_at: nil, event_name: nil)
    serialized_record = {
      record_type: 'conversation',
      conversation: conversation_attributes(conversation),
      message: nil,
      metric_value: metric_value,
      occurred_at: (occurred_at || conversation&.created_at)&.to_i
    }
    serialized_record[:event_name] = event_name if event_name.present?
    serialized_record
  end

  def conversation_attributes(conversation)
    return {} if conversation.blank?

    {
      id: conversation.id,
      display_id: conversation.display_id,
      contact_id: conversation.contact_id,
      contact_name: conversation.contact&.name,
      inbox_id: conversation.inbox_id,
      inbox_name: conversation.inbox&.name,
      assignee_id: conversation.assignee_id,
      assignee_name: conversation.assignee&.name,
      status: conversation.status,
      created_at: conversation.created_at.to_i,
      last_activity_at: conversation.last_activity_at.to_i,
      last_message: last_message_attributes(conversation)
    }
  end

  def message_attributes(message)
    {
      id: message.id,
      content: message.content,
      message_type: message.message_type,
      sender_name: message.sender&.try(:name),
      created_at: message.created_at.to_i
    }
  end

  def last_message_attributes(conversation)
    message = latest_messages_by_conversation_id[conversation.id]
    return if message.blank?

    message_attributes(message)
  end

  def inferred_message_for(event)
    return unless MESSAGE_EVENT_METRICS.include?(metric)
    return if event.conversation.blank? || event.event_end_time.blank?

    inferred_messages_by_event_id[event.id]
  end

  def first_response_event_with_user?(event)
    metric == 'avg_first_response_time' && event.user_id.present?
  end

  def message_inference_range(event)
    (event.event_end_time - 1.second)..(event.event_end_time + 1.second)
  end

  def event_metric_value(event)
    use_business_hours ? event.value_in_business_hours : event.value
  end

  def event_timestamp(event)
    event.event_end_time || event.created_at
  end

  def latest_messages_by_conversation_id
    @latest_messages_by_conversation_id ||= if conversation_ids.blank?
                                              {}
                                            else
                                              latest_messages.index_by(&:conversation_id)
                                            end
  end

  def latest_messages
    Message
      .where(account_id: account.id, conversation_id: conversation_ids)
      .where.not(message_type: :activity)
      .select('DISTINCT ON (messages.conversation_id) messages.*')
      .reorder(Arel.sql('messages.conversation_id, messages.created_at DESC, messages.id DESC'))
      .includes(:sender)
  end

  def inferred_messages_by_event_id
    @inferred_messages_by_event_id ||= inference_events.each_with_object({}) do |event, messages_by_event_id|
      messages_by_event_id[event.id] = inferred_message_candidates.find do |message|
        message_matches_event?(message, event)
      end
    end
  end

  def inferred_message_candidates
    @inferred_message_candidates ||= if inference_events.blank?
                                       []
                                     else
                                       inferred_messages.to_a
                                     end
  end

  def inferred_messages
    Message
      .where(account_id: account.id, conversation_id: inference_events.map(&:conversation_id).uniq)
      .where(created_at: inference_time_range)
      .where(message_type: %i[outgoing template])
      .includes(:sender)
      .reorder(created_at: :desc, id: :desc)
  end

  def message_matches_event?(message, event)
    message.conversation_id == event.conversation_id &&
      message.created_at.between?(
        message_inference_range(event).begin,
        message_inference_range(event).end
      ) &&
      message_sender_matches_event?(message, event)
  end

  def message_sender_matches_event?(message, event)
    return true unless first_response_event_with_user?(event)

    message.sender_id == event.user_id && message.sender_type == 'User'
  end

  def inference_time_range
    event_end_times = inference_events.map(&:event_end_time)

    (event_end_times.min - 1.second)..(event_end_times.max + 1.second)
  end

  def inference_events
    @inference_events ||= records.select do |record|
      record.is_a?(ReportingEvent) && record.conversation_id.present? && record.event_end_time.present?
    end
  end

  def conversation_ids
    @conversation_ids ||= records.filter_map { |record| conversation_id_for(record) }.uniq
  end

  def conversation_id_for(record)
    return record.conversation_id if record.is_a?(Message) || record.is_a?(ReportingEvent)

    record.id
  end
end
