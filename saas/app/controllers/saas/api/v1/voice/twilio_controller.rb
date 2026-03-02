# frozen_string_literal: true

# Handles Twilio Voice webhooks for AI agent voice calls.
# Produces TwiML responses to connect incoming calls to AI agents.
#
# Routes (defined under saas namespace in routes.rb):
#   POST /saas/api/v1/voice/twilio/incoming   → answers the call, connects to media stream
#   POST /saas/api/v1/voice/twilio/status     → call status updates
#   POST /saas/api/v1/voice/twilio/fallback   → fallback TTS pipeline for simple IVR
class Saas::Api::V1::Voice::TwilioController < ActionController::API
  before_action :verify_twilio_signature

  # POST /saas/api/v1/voice/twilio/incoming
  # Returns TwiML that connects the call to a WebSocket Media Stream
  def incoming
    phone_number = params[:To]
    channel = find_voice_channel(phone_number)

    unless channel
      render xml: reject_twiml('No voice channel configured for this number'), status: :ok
      return
    end

    ai_agent = active_ai_agent_for(channel.inbox)
    unless ai_agent&.voice? || ai_agent&.hybrid?
      render xml: reject_twiml('No voice agent available'), status: :ok
      return
    end

    # Create or find conversation
    conversation = find_or_create_conversation(channel, params[:From], params[:CallSid])

    # Return TwiML that starts a Media Stream WebSocket
    render xml: stream_twiml(channel, conversation, ai_agent), status: :ok
  end

  # POST /saas/api/v1/voice/twilio/status
  # Handle call status updates (completed, failed, etc.)
  def status
    call_sid = params[:CallSid]
    call_status = params[:CallStatus]

    Rails.logger.info("[Voice::Twilio] Call #{call_sid} status: #{call_status}")

    if %w[completed failed busy no-answer canceled].include?(call_status)
      conversation = Conversation.find_by('additional_attributes @> ?', { call_sid: call_sid }.to_json)
      conversation&.update!(status: :resolved) if call_status == 'completed'
    end

    head :no_content
  end

  # POST /saas/api/v1/voice/twilio/fallback
  # Simple fallback: gather speech → text agent → TTS → play back
  def fallback
    phone_number = params[:To]
    channel = find_voice_channel(phone_number)
    ai_agent = active_ai_agent_for(channel&.inbox)

    unless ai_agent
      render xml: reject_twiml('No agent available'), status: :ok
      return
    end

    speech_result = params[:SpeechResult]

    if speech_result.blank?
      # First call — gather speech
      render xml: gather_twiml(ai_agent), status: :ok
      return
    end

    # Process speech through text agent
    conversation = find_or_create_conversation(channel, params[:From], params[:CallSid])
    executor = Agent::Executor.new(ai_agent: ai_agent, conversation: conversation)
    result = executor.execute(user_message: speech_result)

    if result.handed_off?
      render xml: handoff_twiml, status: :ok
    else
      render xml: say_and_gather_twiml(result.reply), status: :ok
    end
  end

  private

  # --- Twilio signature verification ---

  def verify_twilio_signature
    return if Rails.env.development? || Rails.env.test?

    phone_number = params[:To] || params[:From]
    channel = find_voice_channel(phone_number)
    return head(:unauthorized) unless channel

    signature = request.headers['X-Twilio-Signature']
    url = request.original_url
    return head(:unauthorized) unless channel.verify_twilio_signature(url, request.POST, signature)
  end

  # --- Lookups ---

  def find_voice_channel(phone_number)
    return nil if phone_number.blank?

    Channel::Voice.find_by(phone_number: phone_number)
  end

  def active_ai_agent_for(inbox)
    return nil unless inbox

    Saas::AiAgentInbox.active_agent_for(inbox)
  end

  def find_or_create_conversation(channel, from_number, call_sid)
    inbox = channel.inbox

    # Find existing open conversation for this caller
    contact = find_or_create_contact(channel.account, from_number)
    conversation = inbox.conversations.where(contact: contact).where.not(status: :resolved).last

    return conversation if conversation

    # Create new conversation
    inbox.conversations.create!(
      account: channel.account,
      contact: contact,
      additional_attributes: { call_sid: call_sid, channel_type: 'voice' }
    )
  end

  def find_or_create_contact(account, phone_number)
    account.contacts.find_by(phone_number: phone_number) ||
      account.contacts.create!(
        phone_number: phone_number,
        name: phone_number
      )
  end

  # --- TwiML builders ---

  def stream_twiml(channel, conversation, ai_agent)
    ws_url = voice_websocket_url(conversation_id: conversation.id, ai_agent_id: ai_agent.id)

    response = Twilio::TwiML::VoiceResponse.new
    response.say(message: greeting_message(ai_agent), voice: twilio_voice(ai_agent))
    connect = response.connect
    connect.stream(url: ws_url)
    response.to_xml
  end

  def gather_twiml(ai_agent)
    fallback_url = "#{ENV.fetch('FRONTEND_URL', request.base_url)}/saas/api/v1/voice/twilio/fallback"

    response = Twilio::TwiML::VoiceResponse.new
    response.say(message: greeting_message(ai_agent), voice: twilio_voice(ai_agent))
    gather = response.gather(
      input: 'speech',
      action: fallback_url,
      method: 'POST',
      speech_timeout: 'auto',
      language: ai_agent.voice_language
    )
    gather.say(message: 'I am listening.', voice: twilio_voice(ai_agent))
    response.to_xml
  end

  def say_and_gather_twiml(text)
    fallback_url = "#{ENV.fetch('FRONTEND_URL', request.base_url)}/saas/api/v1/voice/twilio/fallback"

    response = Twilio::TwiML::VoiceResponse.new
    gather = response.gather(
      input: 'speech',
      action: fallback_url,
      method: 'POST',
      speech_timeout: 'auto',
      language: 'en-US'
    )
    gather.say(message: text)
    response.say(message: 'Thank you for calling. Goodbye.')
    response.hangup
    response.to_xml
  end

  def handoff_twiml
    response = Twilio::TwiML::VoiceResponse.new
    response.say(message: 'Let me transfer you to a human agent. Please hold.')
    response.enqueue(name: 'support')
    response.to_xml
  end

  def reject_twiml(reason)
    response = Twilio::TwiML::VoiceResponse.new
    response.say(message: reason)
    response.hangup
    response.to_xml
  end

  def greeting_message(ai_agent)
    ai_agent.voice_greeting
  end

  def twilio_voice(ai_agent)
    ai_agent.voice_config&.dig('twilio_voice') || 'Polly.Joanna'
  end

  def voice_websocket_url(params)
    host = ENV.fetch('FRONTEND_URL', request.base_url)
    ws_host = host.sub(%r{^http}, 'ws')
    "#{ws_host}/cable?conversation_id=#{params[:conversation_id]}&ai_agent_id=#{params[:ai_agent_id]}"
  end
end
