# frozen_string_literal: true

# ActionCable channel for voice agent WebSocket connections.
# Bridges Twilio Media Streams ↔ Voice Provider via Voice::TwilioBridge.
#
# Twilio's <Stream> TwiML connects directly to ActionCable via /cable.
# The stream sends JSON media events which we forward to the bridge.
class VoiceRealtimeChannel < ApplicationCable::Channel
  def subscribed
    ai_agent = Saas::AiAgent.find_by(id: params[:ai_agent_id])
    conversation = Conversation.find_by(id: params[:conversation_id])

    unless ai_agent&.active? && conversation
      reject
      return
    end

    @bridge = Voice::TwilioBridge.new(
      ai_agent: ai_agent,
      conversation: conversation
    )

    # TwilioBridge calls transmit() on this channel to send audio back to Twilio
    @bridge.start!(twilio_ws: self)
  end

  def unsubscribed
    @bridge&.stop!
  end

  # Called for each incoming WebSocket message (Twilio media events)
  def receive(data)
    @bridge&.handle_twilio_event(data)
  end

  private

  def stream_key
    "voice_realtime_#{params[:conversation_id]}"
  end
end
