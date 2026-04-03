class Voice::CallStatus::Manager
  pattr_initialize [:conversation!, :call_sid]

  ALLOWED_STATUSES = %w[ringing in-progress completed no-answer failed].freeze
  TERMINAL_STATUSES = %w[completed no-answer failed].freeze

  def process_status_update(status, duration: nil, timestamp: nil)
    return unless ALLOWED_STATUSES.include?(status)

    current_status = conversation.additional_attributes&.dig('call_status')
    return if current_status == status
    return if preserve_existing_terminal_status?(current_status, status)

    apply_status(status, duration: duration, timestamp: timestamp)
    update_message(status)
  end

  private

  def apply_status(status, duration:, timestamp:)
    attrs = (conversation.additional_attributes || {}).dup
    attrs['call_status'] = status

    if status == 'in-progress'
      attrs['call_started_at'] ||= timestamp || now_seconds
    elsif TERMINAL_STATUSES.include?(status)
      attrs['call_ended_at'] = timestamp || now_seconds
      attrs['call_duration'] = resolved_duration(attrs, duration, timestamp)
    end

    conversation.update!(
      additional_attributes: attrs,
      last_activity_at: current_time
    )
  end

  def resolved_duration(attrs, provided_duration, timestamp)
    return provided_duration if provided_duration

    started_at = attrs['call_started_at']
    return unless started_at && timestamp

    [timestamp - started_at.to_i, 0].max
  end

  def update_message(status)
    message = latest_voice_call_message
    return unless message

    message.update!(content_attributes: updated_message_attributes(message, status))
  end

  def now_seconds
    current_time.to_i
  end

  def current_time
    @current_time ||= Time.zone.now
  end

  def latest_voice_call_message
    conversation.messages
                .where(content_type: 'voice_call')
                .order(created_at: :desc)
                .first
  end

  def updated_message_attributes(message, status)
    data = (message.content_attributes || {}).deep_dup
    call_data = data['data'] ||= {}
    call_data['status'] = status
    call_data['meta'] ||= {}
    update_duration_meta(data, status)
    data
  end

  def update_duration_meta(data, status)
    duration = conversation.additional_attributes['call_duration']

    if status == 'completed' && duration.present?
      data['data']['meta']['duration'] = duration
    else
      data['data']['meta'].delete('duration')
    end
  end

  def preserve_existing_terminal_status?(current_status, next_status)
    TERMINAL_STATUSES.include?(current_status) &&
      TERMINAL_STATUSES.include?(next_status)
  end
end
