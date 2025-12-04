# frozen_string_literal: true

module Captain::Providers::Openai::UploadFile
  def upload_file(parameters:)
    result = @client.files.upload(parameters: parameters)
    handle_error(result) if result['error']
    result
  end
end
