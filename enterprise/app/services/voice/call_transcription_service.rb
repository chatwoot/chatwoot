class Voice::CallTranscriptionService
  pattr_initialize [:call!]

  def perform
    return unless transcribable?

    transcript = Llm::SpeechToTextService.new(blob: recording_blob, account: call.account).perform
    return if transcript.blank?

    call.update!(transcript: transcript)
    publish(call.message)
  end

  private

  def publish(message)
    return if message.blank?

    # Rebroadcast the message so connected clients pick up the embedded Call
    # payload (now with transcript) without a refetch.
    message.reload.send_update_event

    return unless ChatwootApp.advanced_search_allowed?

    message.reindex
  end

  def transcribable?
    return false if call.transcript.present?
    return false unless call.recording.attached?
    return false unless Llm::SpeechToTextService.available_for?(call.account)

    !Llm::SpeechToTextService.too_large?(recording_blob)
  end

  def recording_blob
    call.recording.blob
  end
end
