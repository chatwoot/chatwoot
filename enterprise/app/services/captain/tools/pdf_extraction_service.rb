require 'pdf-reader'

class Captain::Tools::PdfExtractionService
  include ActiveModel::Validations
  include Captain::Tools::PdfValidationConcern
  include Captain::Tools::PdfContentChunkingConcern

  attr_reader :pdf_source, :errors

  # Fixed PDF processing limits
  MAX_PDF_SIZE = 25.megabytes
  MAX_CHUNK_SIZE = 10_000
  DOWNLOAD_TIMEOUT = 60        # Increased for larger file downloads

  def initialize(pdf_source)
    @pdf_source = pdf_source
    @errors = []
  end

  def perform
    return failure_response(['Invalid PDF source']) if pdf_source.blank?

    validation_result = validate_pdf_source
    return validation_result unless validation_result[:success]

    process_pdf_extraction
  rescue PDF::Reader::MalformedPDFError => e
    handle_malformed_pdf_error(e)
  rescue PDF::Reader::UnsupportedFeatureError => e
    handle_unsupported_feature_error(e)
  rescue Down::TimeoutError => e
    handle_timeout_error(e)
  rescue StandardError => e
    handle_general_error(e)
  end

  def extract_text
    case determine_source_type
    when :url
      active_storage_blob_url? ? extract_from_active_storage_blob : extract_from_url
    when :uploaded_file
      extract_from_uploaded_file
    else
      extract_from_file_path
    end
  end

  private

  def determine_source_type
    return :url if pdf_source.is_a?(String) && pdf_source.start_with?('http')
    return :uploaded_file if pdf_source.respond_to?(:tempfile)

    :file_path
  end

  def extract_from_url
    temp_file = Down.download(
      pdf_source,
      max_size: MAX_PDF_SIZE,
      open_timeout: DOWNLOAD_TIMEOUT,
      read_timeout: DOWNLOAD_TIMEOUT
    )

    begin
      result = extract_from_file(temp_file.path)
    ensure
      temp_file.close
      temp_file.unlink
    end

    result
  end

  def extract_from_uploaded_file
    extract_from_file(pdf_source.tempfile.path)
  end

  def extract_from_file_path
    extract_from_file(pdf_source)
  end

  def active_storage_blob_url?
    pdf_source.include?('/rails/active_storage/blobs/') ||
      (pdf_source.include?('blob') && pdf_source.include?('pdf'))
  end

  def extract_from_active_storage_blob
    blob = find_blob_from_url
    return extract_blob_content(blob) if blob

    Rails.logger.warn 'ActiveStorage blob not found, falling back to URL download'
    extract_from_url
  end

  def extract_blob_content(blob)
    blob.open { |file| extract_from_file(file.path) }
  end

  def find_blob_from_url
    blob_key = extract_blob_key_from_url
    return nil if blob_key.blank?

    ActiveStorage::Blob.find_by(key: blob_key)
  rescue StandardError => e
    Rails.logger.error "Error finding blob with key '#{blob_key}': #{e.message}"
    nil
  end

  def extract_blob_key_from_url
    blob_key = if pdf_source.include?('/rails/active_storage/blobs/')
                 extract_key_from_rails_path
               elsif pdf_source.include?('/blobs/')
                 extract_key_from_blob_path
               end

    blob_key&.split('?')&.first # Remove query parameters
  end

  def extract_key_from_rails_path
    parts = pdf_source.split('/rails/active_storage/blobs/').last.split('/')
    parts.length > 1 && parts[0] != 'redirect' ? parts[0] : parts[1]
  end

  def extract_key_from_blob_path
    pdf_source.split('/blobs/').last.split('/').first
  end

  def extract_from_file(file_path)
    text_content = []

    PDF::Reader.open(file_path) do |reader|
      reader.pages.each_with_index do |page, index|
        page_text = page.text
        next if page_text.blank?

        cleaned_text = clean_text(page_text)
        if cleaned_text.present?
          text_content << {
            page_number: index + 1,
            content: cleaned_text
          }
        end
      rescue StandardError => e
        Rails.logger.warn "Failed to extract text from page #{index + 1}: #{e.message}"
        next
      end
    end

    text_content
  end

  def clean_text(text)
    # Remove form feeds and normalize whitespace
    cleaned = text.tr("\f", "\n")
                  .gsub("\r\n", "\n")
                  .tr("\r", "\n")
                  .gsub(/\s+/, ' ')
                  .gsub(/\n\s*\n\s*\n+/, "\n\n")
                  .strip

    # Remove common PDF artifacts
    cleaned = cleaned.gsub(/^\d+\s*$/, '') # Remove standalone page numbers
                     .gsub(/^[\s\-_=]+$/, '') # Remove separator lines
                     .strip

    (cleaned.presence)
  end

  def pdf_source_type
    case pdf_source
    when String
      pdf_source.start_with?('http') ? 'URL' : 'file_path'
    else
      'uploaded_file'
    end
  end

  def log_extraction_success(chunked_content)
    total_chars = chunked_content.sum { |chunk| chunk[:content].length }
    Rails.logger.info "PDF extraction completed: #{chunked_content.length} chunks, #{total_chars} characters"
    Rails.logger.info "PDF chunks breakdown: #{chunked_content.map do |chunk|
      "Page #{chunk[:page_number]} (#{chunk[:content].length} chars)"
    end.join(', ')}"
  end

  def process_pdf_extraction
    content = extract_text
    return failure_response(['No text content found in PDF']) if content.blank?

    chunked_content = chunk_content(content)
    log_extraction_success(chunked_content)

    success_response(chunked_content)
  end

  def success_response(content)
    { success: true, content: content }
  end

  def failure_response(errors)
    { success: false, errors: errors }
  end

  def handle_malformed_pdf_error(error)
    Rails.logger.error "Malformed PDF (#{pdf_source_type}): #{error.message}"
    failure_response(['Invalid or corrupted PDF format'])
  end

  def handle_unsupported_feature_error(error)
    Rails.logger.error "Unsupported PDF feature (#{pdf_source_type}): #{error.message}"
    failure_response(['PDF contains unsupported features'])
  end

  def handle_timeout_error(error)
    Rails.logger.error "PDF download timeout (#{pdf_source_type}): #{error.message}"
    failure_response(['PDF download timed out'])
  end

  def handle_general_error(error)
    Rails.logger.error "PDF extraction error (#{pdf_source_type}): #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    failure_response(['Failed to process PDF'])
  end
end