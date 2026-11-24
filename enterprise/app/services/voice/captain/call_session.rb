# Links a Twilio call that Captain answers to its Vapi call and Chatwoot conversation.
# Vapi webhooks only carry Vapi's call id, so every webhook looks the session up by it.
class Voice::Captain::CallSession
  TTL = 2.hours
  VAPI_KEY_PREFIX = 'voice_captain:vapi'.freeze
  TWILIO_KEY_PREFIX = 'voice_captain:twilio'.freeze

  attr_reader :account_id, :inbox_id, :conversation_id, :contact_id, :twilio_call_sid

  def initialize(account_id:, inbox_id:, conversation_id:, contact_id:, twilio_call_sid:)
    @account_id = account_id
    @inbox_id = inbox_id
    @conversation_id = conversation_id
    @contact_id = contact_id
    @twilio_call_sid = twilio_call_sid
  end

  # Marks a Twilio call as already offered to Captain, so a redirect back to the call webhook rings agents instead
  def self.mark_twilio_call!(twilio_call_sid)
    Redis::Alfred.setex(twilio_key(twilio_call_sid), '1', TTL)
  end

  def self.twilio_call_marked?(twilio_call_sid)
    Redis::Alfred.get(twilio_key(twilio_call_sid)).present?
  end

  def self.for_vapi_call(vapi_call_id)
    payload = Redis::Alfred.get(vapi_key(vapi_call_id))
    return if payload.blank?

    new(**JSON.parse(payload).symbolize_keys)
  end

  def self.vapi_key(vapi_call_id)
    "#{VAPI_KEY_PREFIX}:#{vapi_call_id}"
  end

  def self.twilio_key(twilio_call_sid)
    "#{TWILIO_KEY_PREFIX}:#{twilio_call_sid}"
  end

  def save!(vapi_call_id)
    Redis::Alfred.setex(self.class.vapi_key(vapi_call_id), to_h.to_json, TTL)
  end

  def to_h
    {
      account_id: account_id,
      inbox_id: inbox_id,
      conversation_id: conversation_id,
      contact_id: contact_id,
      twilio_call_sid: twilio_call_sid
    }
  end

  def conversation
    @conversation ||= Conversation.find_by!(account_id: account_id, id: conversation_id)
  end

  def inbox
    conversation.inbox
  end

  def assistant
    inbox.captain_assistant
  end

  # The state Captain's tools read in chat: which conversation and contact they act on
  def tool_state
    { conversation: { id: conversation_id }, contact: { id: contact_id }, source: 'voice' }
  end
end
