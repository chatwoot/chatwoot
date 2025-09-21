class Voice::CallSessionSyncService
  attr_reader :conversation, :call_sid, :message_call_sid, :from_number, :to_number, :direction

  def initialize(conversation:, call_sid:, from_number:, to_number:, direction:, message_call_sid: nil)
    @conversation = conversation
    @call_sid = call_sid
    @message_call_sid = message_call_sid || call_sid
    @from_number = from_number
    @to_number = to_number
    @direction = direction
  end

  def perform
    ActiveRecord::Base.transaction do
      ensure_conference_sid!
      refresh_conversation_metadata!
      sync_voice_call_message!
    end

    conversation
  end

  private

  def ensure_conference_sid!
    attrs = conversation.additional_attributes || {}
    return if attrs['conference_sid'].present?

    # We always persist the human-readable conference friendly name. Twilio's
    # opaque ConferenceSid is stored separately (see controller callbacks) and
    # is only used to correlate webhook payloads.
    attrs['conference_sid'] = conference_sid_for(conversation)
    conversation.update!(additional_attributes: attrs)
  end

  def refresh_conversation_metadata!
    attrs = (conversation.additional_attributes || {}).dup
    existing_direction = attrs['call_direction']
    if existing_direction.present? && existing_direction != direction
      raise ArgumentError, "Call direction mismatch (existing=#{existing_direction}, incoming=#{direction})"
    end
    attrs['call_direction'] = direction
    attrs['call_status'] ||= 'ringing'
    attrs['last_provider_event_at'] = Time.current.to_i
    attrs['meta'] ||= {}
    attrs['meta']['initiated_at'] ||= Time.current.to_i

    conversation.update!(
      additional_attributes: attrs,
      last_activity_at: Time.current
    )
  end

  def sync_voice_call_message!
    attrs = conversation.additional_attributes || {}
    current_direction = direction

    Voice::CallMessageBuilder.new(
      conversation: conversation,
      direction: current_direction,
      call_sid: message_call_sid,
      conference_sid: attrs['conference_sid'] || conference_sid_for(conversation),
      from_number: origin_number_for(current_direction),
      to_number: target_number_for(current_direction),
      user: agent_for(attrs)
    ).perform
  end

  def origin_number_for(direction)
    return conversation.inbox&.channel&.phone_number || from_number if direction == 'outbound'

    from_number || conversation.inbox&.channel&.phone_number
  end

  def target_number_for(direction)
    return conversation.contact&.phone_number || to_number if direction == 'outbound'

    to_number || conversation.contact&.phone_number
  end

  def agent_for(attrs)
    agent_id = attrs['agent_id']
    return nil unless agent_id

    agent = conversation.account.users.find_by(id: agent_id)
    raise ArgumentError, 'Agent sender required for outbound call sync' if direction == 'outbound' && agent.nil?

    agent
  end

  def conference_sid_for(conversation)
    "conf_account_#{conversation.account_id}_conv_#{conversation.display_id}"
  end
end
