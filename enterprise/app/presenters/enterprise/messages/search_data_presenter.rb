module Enterprise::Messages::SearchDataPresenter
  # Voice-call recordings hang off the Call, not off message attachments, so the
  # transcript is folded into attachments.transcribed_text — the field search
  # already queries for audio-message transcriptions.
  def attachment_data
    transcript = call&.transcript if content_type == 'voice_call'
    return super if transcript.blank?

    (super || []) + [{ transcribed_text: transcript }]
  end
end
