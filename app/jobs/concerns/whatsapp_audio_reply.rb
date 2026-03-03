# frozen_string_literal: true

# Encapsulates ElevenLabs TTS + WhatsApp Media Upload flow.
# Bypasses ActiveStorage/localhost URLs by uploading audio bytes
# directly to WhatsApp Media API and sending via media_id.
module WhatsappAudioReply
  extend ActiveSupport::Concern

  private

  def incoming_has_audio?(message)
    message.attachments.any? { |a| a.file_type.to_s == 'audio' }
  end

  def send_audio_reply(conversation, account, ai_agent, reply_text)
    audio_bytes = generate_elevenlabs_speech(ai_agent, reply_text)
    return create_text_reply(conversation, account, ai_agent, reply_text) if audio_bytes.blank?

    media_id = upload_audio_to_whatsapp(conversation, audio_bytes)
    return create_text_reply(conversation, account, ai_agent, reply_text) if media_id.blank?

    @audio_context = { conversation: conversation, account: account, ai_agent: ai_agent }
    wamid = send_whatsapp_audio_by_id(conversation, media_id)
    create_audio_message(reply_text, audio_bytes, wamid)
  end

  def generate_elevenlabs_speech(ai_agent, text)
    tts = Llm::ElevenlabsTts.new(voice_id: ai_agent.voice_id, model_id: ai_agent.realtime_model)
    tts.generate(text)
  end

  # Creates an outgoing message with the audio attachment in Chatwoot.
  # Sets source_id so SendReplyJob skips it (already sent via direct media upload).
  def create_audio_message(reply_text, audio_bytes, wamid)
    ctx = @audio_context
    message = ctx[:conversation].messages.create!(
      content: reply_text, message_type: :outgoing, account_id: ctx[:account].id,
      inbox_id: ctx[:conversation].inbox_id, source_id: wamid,
      content_attributes: { ai_generated: true, ai_agent_id: ctx[:ai_agent].id }
    )
    attach_audio_blob(message, ctx[:account], audio_bytes)
    message
  end

  def attach_audio_blob(message, account, audio_bytes)
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(audio_bytes), filename: 'reply.ogg', content_type: 'audio/ogg')
    message.attachments.create!(account_id: account.id, file_type: :audio, file: blob)
  rescue StandardError => e
    Rails.logger.warn "[AI_AGENT] Failed to attach audio blob: #{e.class} — #{e.message}"
  end

  def upload_audio_to_whatsapp(conversation, audio_bytes)
    uri = whatsapp_media_uri(conversation)
    request = build_media_upload_request(uri, conversation, audio_bytes)
    response = execute_https(uri, request)
    handle_media_upload_response(response)
  rescue StandardError => e
    Rails.logger.warn "[AI_AGENT] WhatsApp media upload error: #{e.class} — #{e.message}"
    nil
  end

  def build_media_upload_request(uri, conversation, audio_bytes)
    token = conversation.inbox.channel.provider_config['api_key']
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{token}"
    request.set_form(
      [['messaging_product', 'whatsapp'], ['type', 'audio/ogg'],
       ['file', audio_bytes, { filename: 'reply.ogg', content_type: 'audio/ogg' }]],
      'multipart/form-data'
    )
    request
  end

  def handle_media_upload_response(response)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn "[AI_AGENT] WhatsApp media upload failed: #{response.code} — #{response.body.truncate(200)}"
      return nil
    end

    media_id = JSON.parse(response.body)['id']
    Rails.logger.info "[AI_AGENT] WhatsApp media uploaded: #{media_id}"
    media_id
  end

  # Returns the wamid from WhatsApp's response so we can set source_id on the Chatwoot message.
  def send_whatsapp_audio_by_id(conversation, media_id)
    channel = conversation.inbox.channel
    phone_id = channel.provider_config['phone_number_id']
    token = channel.provider_config['api_key']
    phone = contact_phone(conversation)
    url = "#{whatsapp_api_base}/v13.0/#{phone_id}/messages"

    response = HTTParty.post(
      url,
      headers: { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' },
      body: { messaging_product: 'whatsapp', recipient_type: 'individual', to: phone, type: 'audio', audio: { id: media_id } }.to_json
    )
    Rails.logger.info "[AI_AGENT] WhatsApp audio sent: #{response.code} — #{response.body}"
    extract_wamid(response)
  rescue StandardError => e
    Rails.logger.warn "[AI_AGENT] WhatsApp audio send failed: #{e.class} — #{e.message}"
    nil
  end

  def extract_wamid(response)
    return nil unless response.code == 200

    (response.parsed_response || JSON.parse(response.body)).dig('messages', 0, 'id')
  rescue StandardError
    nil
  end

  def whatsapp_media_uri(conversation)
    phone_id = conversation.inbox.channel.provider_config['phone_number_id']
    URI("#{whatsapp_api_base}/v13.0/#{phone_id}/media")
  end

  def execute_https(uri, request)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 10
    http.read_timeout = 30
    http.request(request)
  end

  def whatsapp_api_base
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end
end
