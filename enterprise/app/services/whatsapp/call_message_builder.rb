class Whatsapp::CallMessageBuilder
  WHATSAPP_TO_VOICE_STATUS = {
    'ringing' => 'ringing',
    'accepted' => 'in-progress',
    'rejected' => 'failed',
    'missed' => 'no-answer',
    'ended' => 'completed',
    'failed' => 'failed'
  }.freeze

  def self.create!(conversation:, wa_call:, user: nil)
    new(conversation: conversation, wa_call: wa_call, user: user).create!
  end

  def self.update_status!(wa_call:, status: nil, agent: nil, duration_seconds: nil)
    new(conversation: wa_call.conversation, wa_call: wa_call).update_status!(
      status: status, agent: agent, duration_seconds: duration_seconds
    )
  end

  def self.update_recording_url!(wa_call:)
    message = wa_call.message
    return unless message

    data = (message.content_attributes || {}).dup
    data['data'] ||= {}
    data['data']['recording_url'] = wa_call.recording_url
    message.update!(content_attributes: data)
  end

  def initialize(conversation:, wa_call:, user: nil)
    @conversation = conversation
    @wa_call = wa_call
    @user = user
  end

  def create!
    params = {
      content: 'WhatsApp Call',
      message_type: message_type,
      content_type: 'voice_call',
      content_attributes: { 'data' => build_data_payload }
    }

    Messages::MessageBuilder.new(sender, conversation, params).perform
  end

  def update_status!(status:, agent: nil, duration_seconds: nil)
    message = wa_call.message
    return unless message

    data = (message.content_attributes || {}).dup
    data['data'] ||= {}
    data['data']['status'] = map_status(status) if status
    data['data']['accepted_by'] = { 'id' => agent.id, 'name' => agent.name } if agent
    data['data']['duration_seconds'] = duration_seconds if duration_seconds

    message.update!(content_attributes: data)
    message
  end

  private

  attr_reader :conversation, :wa_call, :user

  def build_data_payload
    {
      'call_sid' => wa_call.call_id,
      'status' => map_status(wa_call.status),
      'call_direction' => wa_call.direction,
      'call_source' => 'whatsapp',
      'wa_call_id' => wa_call.id,
      'from_number' => from_number,
      'to_number' => to_number,
      'meta' => { 'created_at' => Time.zone.now.to_i }
    }
  end

  def message_type
    wa_call.direction == 'outbound' ? 'outgoing' : 'incoming'
  end

  def sender
    return user if wa_call.direction == 'outbound' && user

    conversation.contact
  end

  def from_number
    if wa_call.direction == 'inbound'
      conversation.contact&.phone_number
    else
      conversation.inbox.channel&.phone_number
    end
  end

  def to_number
    if wa_call.direction == 'inbound'
      conversation.inbox.channel&.phone_number
    else
      conversation.contact&.phone_number
    end
  end

  def map_status(status)
    WHATSAPP_TO_VOICE_STATUS[status] || status
  end
end
