# frozen_string_literal: true

module Captain::Providers::Openai::Transcribe
  def transcribe(parameters:)
    result = @client.audio.transcribe(parameters: parameters)
    handle_error(result) if result['error']
    result
  end
end
