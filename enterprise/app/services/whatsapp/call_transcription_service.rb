class Whatsapp::CallTranscriptionService < Llm::LegacyBaseOpenAiService
  WHISPER_MODEL = 'whisper-1'.freeze

  attr_reader :wa_call, :account

  def initialize(wa_call)
    super()
    @wa_call = wa_call
    @account = wa_call.account
  end

  def perform
    return { error: 'Transcription not available' } unless can_transcribe?
    return { error: 'No recording attached' } unless wa_call.recording.attached?

    transcribed_text = transcribe_audio
    update_call_and_message(transcribed_text)
    { success: true, transcript: transcribed_text }
  rescue Faraday::UnauthorizedError
    Rails.logger.warn('[WHATSAPP CALL] Skipping transcription: OpenAI configuration is invalid (401)')
    { error: 'OpenAI configuration is invalid' }
  end

  private

  def can_transcribe?
    account.feature_enabled?('captain_integration') &&
      account.usage_limits[:captain][:responses][:current_available].positive?
  end

  def transcribe_audio
    temp_file_path = fetch_audio_file
    transcribed_text = nil

    File.open(temp_file_path, 'rb') do |file|
      response = @client.audio.transcribe(
        parameters: { model: WHISPER_MODEL, file: file, temperature: 0.4 }
      )
      transcribed_text = response['text']
    end

    transcribed_text
  ensure
    FileUtils.rm_f(temp_file_path) if temp_file_path.present?
  end

  def fetch_audio_file
    blob = wa_call.recording.blob
    temp_dir = Rails.root.join('tmp/uploads/call-transcriptions')
    FileUtils.mkdir_p(temp_dir)

    extension = extension_from_content_type(blob.content_type)
    temp_file_path = File.join(temp_dir, "#{blob.key}.#{extension}")

    File.open(temp_file_path, 'wb') do |file|
      blob.open { |blob_file| IO.copy_stream(blob_file, file) }
    end

    temp_file_path
  end

  def update_call_and_message(transcribed_text)
    return if transcribed_text.blank?

    wa_call.update!(transcript: transcribed_text)
    account.increment_response_usage

    message = wa_call.message
    return unless message

    data = (message.content_attributes || {}).dup
    data['data'] ||= {}
    data['data']['transcript'] = transcribed_text
    data['data']['recording_url'] = wa_call.recording_url
    message.update!(content_attributes: data)
  end

  def extension_from_content_type(content_type)
    subtype = content_type.to_s.downcase.split(';').first.to_s.split('/').last.to_s
    { 'webm' => 'webm', 'ogg' => 'ogg', 'x-m4a' => 'm4a', 'x-wav' => 'wav', 'mpeg' => 'mp3' }.fetch(subtype, 'webm')
  end
end
