class Captain::Llm::PdfProcessingService < Llm::BaseOpenAiService
  def initialize(document)
    @document = document
    super()
  end

  def process
    process_for_pagination
  end

  private

  attr_reader :document

  def upload_pdf_to_openai
    pdf_file = document.pdf_file

    Tempfile.create(['pdf_upload', '.pdf'], binmode: true) do |temp_file|
      temp_file.write(pdf_file.download)
      temp_file.close

      File.open(temp_file.path, 'rb') do |file|
        @client.files.upload(
          parameters: {
            file: file,
            purpose: 'assistants'
          }
        )
      end
    end
  end

  def process_for_pagination
    return 'PDF ready for paginated processing' if document.openai_file_id.present?

    openai_response = upload_pdf_to_openai
    file_id = openai_response['id']

    raise I18n.t('captain.documents.pdf_upload_failed') if file_id.blank?

    document.store_openai_file_id(file_id)
    Rails.logger.info "PDF uploaded successfully with file_id: #{file_id}"

    "PDF ready for paginated processing (file_id: #{file_id})"
  end
end
