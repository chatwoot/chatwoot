class Voice::CallSessionSyncService
  attr_reader :conversation, :call_sid, :message_call_sid, :from_number, :to_number, :direction

  def initialize(conversation:, call_sid:, leg:, message_call_sid: nil)
    @conversation = conversation
    @call_sid = call_sid
    @message_call_sid = message_call_sid || call_sid
    @from_number = leg[:from_number]
    @to_number = leg[:to_number]
    @direction = leg[:direction]
  end

  def perform
    ActiveRecord::Base.transaction do
      attrs = refreshed_attributes
      conversation.update!(
        additional_attributes: attrs,
        last_activity_at: current_time
      )
      sync_voice_call_message!(attrs)
    end

    conversation
  end

  private

  def refreshed_attributes
    attrs = (conversation.additional_attributes || {}).dup
    attrs['call_direction'] = direction
    attrs['call_status'] ||= 'ringing'
    attrs['conference_sid'] ||= Voice::Conference::Name.for(conversation)
    attrs['meta'] ||= {}
    attrs['meta']['initiated_at'] ||= current_timestamp
    attrs
  end

  def sync_voice_call_message!(attrs)
    Voice::CallMessageBuilder.perform!(
      conversation: conversation,
      direction: direction,
      payload: {
        call_sid: message_call_sid,
        status: attrs['call_status'],
        conference_sid: attrs['conference_sid'],
        from_number: origin_number_for(direction),
        to_number: target_number_for(direction)
      },
      user: agent_for(attrs),
      timestamps: {
        created_at: attrs.dig('meta', 'initiated_at'),
        ringing_at: attrs.dig('meta', 'ringing_at')
      }
    )
  end

  def origin_number_for(current_direction)
    return outbound_origin if current_direction == 'outbound'

    from_number.presence || inbox_number
  end

  def target_number_for(current_direction)
    return conversation.contact&.phone_number || to_number if current_direction == 'outbound'

    to_number || conversation.contact&.phone_number
  end

  def agent_for(attrs)
    agent_id = attrs['agent_id']
    return nil unless agent_id

    agent = conversation.account.users.find_by(id: agent_id)
    raise ArgumentError, 'Agent sender required for outbound call sync' if direction == 'outbound' && agent.nil?

    agent
  end

  def current_timestamp
    @current_timestamp ||= current_time.to_i
  end

  def current_time
    @current_time ||= Time.zone.now
  end

  def outbound_origin
    inbox_number || from_number
  end

  def inbox_number
    conversation.inbox&.channel&.phone_number
  end
end
