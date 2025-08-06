class Captain::Llm::PdfProcessingService < Llm::BaseOpenAiService
  def initialize(document)
    @document = document
    super()
  end

  def process
    # We only use paginated processing now - just upload and store file_id
    process_for_pagination
  end

  private

  attr_reader :document

  def upload_pdf_to_openai
    pdf_file = document.pdf_file

    # Create a temporary file from the attached PDF
    temp_file = Tempfile.new(['pdf_upload', '.pdf'])
    temp_file.binmode
    temp_file.write(pdf_file.download)
    temp_file.close

    begin
      File.open(temp_file.path, 'rb') do |file|
        @client.files.upload(
          parameters: {
            file: file,
            purpose: 'assistants'
          }
        )
      end
    ensure
      temp_file.unlink
    end
  end

  def process_for_pagination
    # For paginated processing, we only need to upload the PDF and store the file_id
    # No content extraction is needed as the paginated FAQ generator will access the file directly
    if @document.openai_file_id.present?
      Rails.logger.info "PDF already uploaded with file_id: #{@document.openai_file_id}"
      return 'PDF ready for paginated processing'
    end

    # Upload PDF to OpenAI
    openai_response = upload_pdf_to_openai
    file_id = openai_response['id']

    raise 'Failed to upload PDF to OpenAI' unless file_id

    # Store the file ID for future use
    document.store_openai_file_id(file_id)

    Rails.logger.info "PDF uploaded successfully with file_id: #{file_id}"
    "PDF ready for paginated processing (file_id: #{file_id})"
  end
end
