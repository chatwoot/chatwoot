# Transcribes a standalone audio upload coming from the web widget microphone
# and returns the text, without persisting a message or consuming Captain
# response credits. Reuses the Captain OpenAI configuration for the client.
class Messages::WidgetAudioTranscriptionService < Llm::LegacyBaseOpenAiService
  TRANSCRIPTION_MODEL = 'gpt-4o-mini-transcribe'.freeze
  # OpenAI's transcription endpoint hard limit is 25 MB decimal (25_000_000),
  # not binary — see Messages::AudioTranscriptionService for context.
  TRANSCRIPTION_BYTE_LIMIT = 25_000_000

  def initialize(account, audio_file)
    super()
    @account = account
    @audio_file = audio_file
  end

  def perform
    return { error: 'Audio transcription is not enabled' } unless can_transcribe?
    return { error: 'Audio too large for transcription' } if audio_too_large?

    { success: true, transcription: transcribe_audio }
  rescue Faraday::UnauthorizedError
    Rails.logger.warn('Skipping widget audio transcription: OpenAI configuration is invalid or disabled (401).')
    { error: 'Transcription service is unavailable' }
  end

  private

  def can_transcribe?
    @account.audio_transcriptions.present?
  end

  def audio_too_large?
    @audio_file.size.to_i > TRANSCRIPTION_BYTE_LIMIT
  end

  def transcribe_audio
    temp_file_path = stage_audio_file

    File.open(temp_file_path, 'rb') do |file|
      # temperature: 0.0 minimises hallucinations on silence / near-silent audio.
      response = @client.audio.transcribe(
        parameters: {
          model: TRANSCRIPTION_MODEL,
          file: file,
          temperature: 0.0
        }
      )
      response['text'].to_s.strip
    end
  ensure
    FileUtils.rm_f(temp_file_path) if temp_file_path.present?
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
