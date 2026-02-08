module Enterprise::Concerns::Attachment
  extend ActiveSupport::Concern

  included do
    after_create_commit :enqueue_audio_transcription
  end

  private

  def enqueue_audio_transcription
    return unless file_type.to_sym == :audio

    Messages::AudioTranscriptionJob.perform_later(id)
  end
end
