class Captain::Tools::PdfOpenaiService
  include ActiveModel::Validations

  class ProcessingError < StandardError; end

  attr_reader :pdf_source

  MAX_PDF_SIZE = 25.megabytes
  OPENAI_PURPOSE = 'assistants'.freeze
  API_KEY_CONFIG = 'CAPTAIN_OPEN_AI_API_KEY'.freeze

  def initialize(pdf_source)
    @pdf_source = pdf_source
  end

  def perform
    return failure_response(['Invalid PDF source']) if pdf_source.blank?

    file_response = upload_pdf_to_openai
    return file_response unless file_response[:success]

    build_success_response(file_response[:file_id])
  rescue ProcessingError => e
    failure_response([e.message])
  rescue StandardError => e
    Rails.logger.error "PDF processing error: #{e.message}"
    failure_response(['An unexpected error occurred while processing the PDF'])
  end

  private

  def openai_client
    @openai_client ||= OpenAI::Client.new(
      access_token: api_key,
      log_errors: Rails.env.development?
    )
  end

  def api_key
    @api_key ||= InstallationConfig.find_by!(name: API_KEY_CONFIG).value
  rescue ActiveRecord::RecordNotFound
    raise ProcessingError, 'OpenAI API key not configured'
  end

  def upload_pdf_to_openai
    file_content = prepare_pdf_content
    return failure_response(['Could not retrieve PDF content']) unless file_content

    validate_pdf_size!(file_content)

    response = openai_client.files.upload(
      parameters: {
        file: file_content,
        purpose: OPENAI_PURPOSE
      }
    )

    { success: true, file_id: response['id'] }
  rescue OpenAI::Error => e
    failure_response(["OpenAI upload failed: #{e.message}"])
  end

  def prepare_pdf_content
    attachment = extract_attachment
    return nil unless attachment&.blob

    blob = attachment.blob
    create_file_io(blob.download, blob.filename.to_s, blob.content_type)
  rescue StandardError => e
    Rails.logger.error "Failed to prepare PDF content: #{e.message}"
    nil
  end

  def extract_attachment
    return pdf_source unless pdf_source.is_a?(ActiveStorage::Attached::One)

    pdf_source.attachment
  end

  def validate_pdf_size!(file_content)
    size = file_content.size
    return if size <= MAX_PDF_SIZE

    raise ProcessingError, "PDF size (#{(size / 1.megabyte).round(2)}MB) exceeds maximum allowed size (#{MAX_PDF_SIZE / 1.megabyte}MB)"
  end

  def create_file_io(content, filename, content_type)
    StringIO.new(content).tap do |io|
      io.define_singleton_method(:path) { filename }
      io.define_singleton_method(:content_type) { content_type }
    end
  end

  def build_success_response(file_id)
    success_response([{
                       content: file_id,
                       metadata: {
                         openai_file_id: file_id,
                         processing_type: 'direct_pdf'
                       }
                     }])
  end

  def success_response(content)
    {
      success: true,
      content: content
    }
  end

  def failure_response(errors)
    {
      success: false,
      errors: errors
    }
  end
end