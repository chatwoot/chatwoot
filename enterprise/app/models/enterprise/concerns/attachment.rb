module Enterprise::Concerns::Attachment
  extend ActiveSupport::Concern

  included do
    after_create_commit :enqueue_audio_transcription
    # Broadcast the message update so the FE bubble picks up the new audio
    # attachment immediately. Without this, the FE has to wait until Whisper
    # finishes (or fall back to a page refresh) — and if Whisper returns blank,
    # the bubble never gets the audio at all.
    after_create_commit :broadcast_message_update_for_audio
  end

  private

  def enqueue_audio_transcription
    return unless file_type.to_sym == :audio

    # No file.attached? guard: the social-media ingest path saves the
    # Attachment before attaching the blob. AudioTranscriptionJob retries
    # on ActiveStorage::FileNotFoundError to ride out that race.
    Messages::AudioTranscriptionJob.perform_later(id)
  end

  def broadcast_message_update_for_audio
    return unless file_type.to_sym == :audio
    return unless message
    # Without an attached file, the message serializer's audio_metadata path
    # dereferences `file.metadata[:width]` on nil and raises. The pre-attach
    # broadcast wouldn't carry useful audio info anyway — skip until upload completes.
    return unless file.attached?

    message.reload.send_update_event
  end
end
