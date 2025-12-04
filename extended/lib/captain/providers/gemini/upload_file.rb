# frozen_string_literal: true

module Captain::Providers::Gemini::UploadFile
  # TODO: Implement Gemini file upload using Files API
  # POST https://generativelanguage.googleapis.com/upload/v1beta/files?key={API_KEY}
  #
  # Key implementation notes:
  # - Use multipart/form-data upload
  # - Returns file URI for use in generateContent requests
  def upload_file(parameters:)
    raise NotImplementedError, 'Gemini file upload is not yet implemented. Please use OpenAI provider.'
  end
end
