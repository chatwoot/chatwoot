class Voice::CallMessageBuilder
  def initialize(call)
    @call = call
  end

  def perform!
    call.message || create_message!
  end

  def update_status!(status:, agent: nil, duration_seconds: nil)
    message = call.message
    return unless message

    patch = {
      'status' => status&.to_s&.tr('_', '-'),
      'accepted_by' => agent && { 'id' => agent.id, 'name' => agent.name },
      'duration_seconds' => duration_seconds
    }.compact

    message.update!(content_attributes: (message.content_attributes || {}).deep_merge('data' => patch))
    message
  end

  # Every client learns when an agent dismisses the ring. Called under the call's row lock, which
  # a status change also takes, so the status on the message stays current.
  def update_ring!
    message = call.message
    return if message.nil?

    message.update!(content_attributes: message.content_attributes.deep_merge('data' => { 'ring_user_ids' => ring_user_ids }))
  end

  private

  attr_reader :call

  def create_message!
    params = {
      content: I18n.t("conversations.messages.voice_call.#{call.provider}"),
      message_type: call.outgoing? ? 'outgoing' : 'incoming',
      content_type: 'voice_call',
      content_attributes: { 'data' => build_data_payload }
    }
    Messages::MessageBuilder.new(sender, call.conversation, params).perform
  end

  def sender
    call.outgoing? ? call.accepted_by_agent : call.contact
  end

  # call_source lets the FE disambiguate WhatsApp vs Twilio without re-fetching the Call.
  def build_data_payload
    {
      'call_id' => call.id,
      'call_sid' => call.provider_call_id,
      'call_source' => call.provider,
      'call_direction' => call.direction_label,
      'status' => call.display_status,
      'ring_user_ids' => (ring_user_ids if call.twilio? && call.incoming?)
    }.compact
  end

  # The agents whose ringing card shows an inbound Twilio call: those it rang who have not dismissed it
  def ring_user_ids = call.ring_state.fetch('ring_recipient_ids', []) - call.dismissed_user_ids
end
