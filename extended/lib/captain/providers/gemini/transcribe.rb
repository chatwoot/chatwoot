# frozen_string_literal: true

module Captain::Providers::Gemini::Transcribe
  # TODO: Implement Gemini audio transcription using multimodal input
  # POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={API_KEY}
  #
  # Key implementation notes:
  # - Use inline_data with base64 encoded audio and mime_type
  # - Prompt: "Transcribe this audio file. Return only the transcription text."
  # - Supported formats: mp3, mp4, wav, aac, flac, ogg, webm
  def transcribe(parameters:)
    raise NotImplementedError, 'Gemini transcription is not yet implemented. Please use OpenAI provider.'
  end
end
