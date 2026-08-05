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
      'status' => call.display_status
    }
  end
end
