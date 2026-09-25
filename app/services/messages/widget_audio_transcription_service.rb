# Transcribes a standalone audio upload coming from the web widget microphone
# and returns the text, without persisting a message. Driven entirely by ENV
# (see Widget::AudioTranscriptionConfig) so it does not depend on Captain.
class Messages::WidgetAudioTranscriptionService
  TRANSCRIPTION_MODEL = Widget::AudioTranscriptionConfig::DEFAULT_MODEL
  # OpenAI's transcription endpoint hard limit is 25 MB decimal (25_000_000),
  # not binary — using the binary form leaks the 25.0-26.2 MB range as 413s.
  TRANSCRIPTION_BYTE_LIMIT = 25_000_000

  def initialize(audio_file)
    @audio_file = audio_file
  end

  def perform
    return { error: 'Audio transcription is not configured' } unless Widget::AudioTranscriptionConfig.configured?
    return { error: 'Audio too large for transcription' } if audio_too_large?

    { success: true, transcription: transcribe_audio }
  rescue Faraday::UnauthorizedError
    Rails.logger.warn('Skipping widget audio transcription: OpenAI configuration is invalid or disabled (401).')
    { error: 'Transcription service is unavailable' }
  end

  private

  def client
    @client ||= OpenAI::Client.new(
      access_token: Widget::AudioTranscriptionConfig.api_key,
      uri_base: Widget::AudioTranscriptionConfig.endpoint,
      log_errors: Rails.env.development?
    )
  end

  def audio_too_large?
    @audio_file.size.to_i > TRANSCRIPTION_BYTE_LIMIT
  end

  def transcribe_audio
    temp_file_path = stage_audio_file

    File.open(temp_file_path, 'rb') do |file|
      response = client.audio.transcribe(parameters: transcription_parameters(file))
      response['text'].to_s.strip
    end
  ensure
    FileUtils.rm_f(temp_file_path) if temp_file_path.present?
  end

  def transcription_parameters(file)
    {
      model: Widget::AudioTranscriptionConfig.model,
      file: file,
      # temperature: 0.0 minimises hallucinations on silence / near-silent audio.
      temperature: 0.0,
      prompt: Widget::AudioTranscriptionConfig.prompt,
      language: Widget::AudioTranscriptionConfig.language
    }.compact
  end

  # OpenAI infers the audio format from the filename extension, so the temp file
  # must carry a real extension derived from the upload's name or content type.
  def stage_audio_file
    temp_dir = Rails.root.join('tmp/uploads/widget-audio-transcriptions')
    FileUtils.mkdir_p(temp_dir)
    temp_file_path = File.join(temp_dir, "#{SecureRandom.uuid}#{audio_extension}")
    IO.copy_stream(@audio_file.tempfile, temp_file_path)
    temp_file_path
  end

  def audio_extension
    extension = File.extname(@audio_file.original_filename.to_s)
    return extension if extension.present?

    subtype = @audio_file.content_type.to_s.split(';').first.to_s.split('/').last.to_s
    subtype.present? ? ".#{subtype}" : '.webm'
  end
end
