class Messages::GroqAudioTranscriptionService
  GROQ_API_URL = 'https://api.groq.com/openai/v1/audio/transcriptions'.freeze
  WHISPER_MODEL = 'whisper-large-v3-turbo'.freeze

  attr_reader :attachment, :message

  def initialize(attachment)
    @attachment = attachment
    @message = attachment.message
  end

  def perform
    return { error: 'Transcription already exists' } if attachment.meta&.[]('transcribed_text').present?
    return { error: 'Groq API key not configured' } if groq_api_key.blank?

    transcribed_text = transcribe_audio
    { success: true, transcribed_text: transcribed_text }
  rescue StandardError => e
    Rails.logger.error "Groq audio transcription failed: #{e.message}"
    { error: e.message }
  end

  private

  def groq_api_key
    ENV.fetch('GROQ_API_KEY', nil)
  end

  def fetch_audio_file
    blob = attachment.file.blob
    temp_dir = Rails.root.join('tmp/uploads/audio-transcriptions')
    FileUtils.mkdir_p(temp_dir)
    temp_file_name = "#{blob.key}-#{blob.filename}"

    if blob.filename.extension_without_delimiter.blank?
      extension = extension_from_content_type(blob.content_type)
      temp_file_name = "#{temp_file_name}.#{extension}" if extension.present?
    end

    temp_file_path = File.join(temp_dir, temp_file_name)

    File.open(temp_file_path, 'wb') do |file|
      blob.open do |blob_file|
        IO.copy_stream(blob_file, file)
      end
    end

    temp_file_path
  end

  def transcribe_audio
    temp_file_path = fetch_audio_file

    conn = Faraday.new do |f|
      f.request :multipart
      f.adapter :net_http
    end

    response = conn.post(GROQ_API_URL) do |req|
      req.headers['Authorization'] = "Bearer #{groq_api_key}"
      req.body = {
        file: Faraday::Multipart::FilePart.new(
          File.open(temp_file_path, 'rb'),
          attachment.file.blob.content_type,
          File.basename(temp_file_path)
        ),
        model: WHISPER_MODEL
      }
    end

    result = JSON.parse(response.body)
    raise result.dig('error', 'message') || 'Transcription failed' if result['error'].present?

    transcribed_text = result['text']
    update_transcription(transcribed_text)
    transcribed_text
  ensure
    FileUtils.rm_f(temp_file_path) if temp_file_path.present?
  end

  def update_transcription(transcribed_text)
    return if transcribed_text.blank?

    attachment.update!(meta: { transcribed_text: transcribed_text })
    message.reload.send_update_event
  end

  def extension_from_content_type(content_type)
    subtype = content_type.to_s.downcase.split(';').first.to_s.split('/').last.to_s
    return if subtype.blank?

    {
      'x-m4a' => 'm4a',
      'x-wav' => 'wav',
      'x-mp3' => 'mp3'
    }.fetch(subtype, subtype)
  end
end
