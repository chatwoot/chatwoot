class Captain::Llm::PdfProcessingService < Llm::BaseOpenAiService
  def initialize(document)
    super()
    @document = document
  end

  def process
    return if document.openai_file_id.present?

    file_id = upload_pdf_to_openai
    raise CustomExceptions::PdfUploadError, I18n.t('captain.documents.pdf_upload_failed') if file_id.blank?

    document.store_openai_file_id(file_id)
  end

  private

  attr_reader :document

  def upload_pdf_to_openai
    with_tempfile do |temp_file|
      response = @client.files.upload(
        parameters: {
          file: temp_file,
          purpose: 'assistants'
        }
      )
      response['id']
    end
  end

  def with_tempfile(&)
    Tempfile.create(['pdf_upload', '.pdf'], binmode: true) do |temp_file|
      temp_file.write(document.pdf_file.download)
      temp_file.close

      File.open(temp_file.path, 'rb', &)
    end
  end
end
