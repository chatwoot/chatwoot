# frozen_string_literal: true

class Twilio::RecordingController < ActionController::Base
  skip_forgery_protection

  # POST /twilio/recording_callback
  # This endpoint is called by Twilio when a call recording is available
  def recording_callback
    conference_sid = params['conference_sid']
    call_sid = params['CallSid']
    recording_url = params['RecordingUrl']
    recording_sid = params['RecordingSid']
    account_id = params['account_id']
    Rails.logger.info("[Twilio::RecordingController] Incoming recording_callback with params: #{params.inspect}")
    unless recording_url && account_id && (conference_sid || call_sid)
      Rails.logger.warn("[Twilio::RecordingController] Missing required params. recording_url: #{recording_url}, account_id: #{account_id}, conference_sid: #{conference_sid}, call_sid: #{call_sid}")
      return head :bad_request
    end

    # Find the account
    account = Account.find_by(id: account_id)
    unless account
      Rails.logger.warn("[Twilio::RecordingController] Account not found for id: #{account_id}")
      return head :not_found
    end

    # Prefer lookup by conference_sid (most robust for conference recordings)
    conversation = if conference_sid
      account.conversations.find_by("additional_attributes ->> 'conference_sid' = ?", conference_sid)
    elsif call_sid
      account.conversations.find_by("additional_attributes ->> 'call_sid' = ?", call_sid)
    end
    unless conversation
      Rails.logger.warn("[Twilio::RecordingController] Conversation not found for conference_sid: #{conference_sid} or call_sid: #{call_sid}")
      return head :not_found
    end

    # Find the original voice call message (should be unique per conference)
    message = conversation.messages.voice_call.order(:created_at).first
    unless message
      Rails.logger.warn("[Twilio::RecordingController] No voice_call message found in conversation_id: #{conversation.id}")
      return head :not_found
    end

    # Download the recording from Twilio
    begin
      Rails.logger.info("[Twilio::RecordingController] Downloading recording from: #{recording_url}.mp3")
      file = URI.open(recording_url + '.mp3')
    rescue => e
      Rails.logger.error("[Twilio::RecordingController] Failed to download recording: #{e.message}")
      return head :internal_server_error
    end

    # Attach the audio file to the message as an audio attachment
    begin
      att = message.attachments.create!(
        account_id: account.id,
        file: {
          io: file,
          filename: "twilio_recording_#{recording_sid}.mp3",
          content_type: 'audio/mpeg'
        },
        file_type: :audio,
        external_url: recording_url + '.mp3',
        meta: { recording_sid: recording_sid, conference_sid: conference_sid, call_sid: call_sid }
      )
      Rails.logger.info("[Twilio::RecordingController] Successfully attached recording to message_id: #{message.id}, attachment_id: #{att.id}")
    rescue => e
      Rails.logger.error("[Twilio::RecordingController] Failed to attach recording: #{e.message}")
      return head :internal_server_error
    end

    # Optionally, update message content_attributes to indicate recording is attached
    content_attributes = message.content_attributes || {}
    content_attributes['recording_attached'] = true
    content_attributes['conference_sid'] = conference_sid if conference_sid
    message.update!(content_attributes: content_attributes)

    head :ok
  end
end
