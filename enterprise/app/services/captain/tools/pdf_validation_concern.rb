module Captain::Tools::PdfValidationConcern
  extend ActiveSupport::Concern

  private

  def validate_pdf_source
    case determine_source_type
    when :url then validate_url
    when :uploaded_file then validate_uploaded_file
    else validate_file_path
    end

    { success: true }
  rescue StandardError => e
    Rails.logger.error "PDF validation failed: #{e.message}"
    { success: false, errors: [e.message] }
  end

  def validate_url
    uri = parse_url
    validate_url_format(uri)
    validate_url_length
    validate_url_scheme(uri)
  end

  def parse_url
    URI.parse(pdf_source)
  rescue URI::InvalidURIError
    raise StandardError, 'Malformed URL'
  end

  def validate_url_format(uri)
    raise StandardError, 'Invalid URL format' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  end

  def validate_url_length
    raise StandardError, 'URL too long' if pdf_source.length > 2048
  end

  def validate_url_scheme(uri)
    raise StandardError, 'Invalid URL scheme' unless %w[http https].include?(uri.scheme)
  end

  def validate_uploaded_file
    validate_file_object
    validate_file_size
    validate_file_type
    validate_file_not_empty
  end

  def validate_file_object
    raise StandardError, 'File object is invalid' unless pdf_source.respond_to?(:size) && pdf_source.respond_to?(:content_type)
  end

  def validate_file_size
    raise StandardError, "File too large (max #{self.class::MAX_PDF_SIZE / 1.megabyte}MB)" if pdf_source.size > self.class::MAX_PDF_SIZE
  end

  def validate_file_type
    raise StandardError, 'Invalid file type' unless pdf_source.content_type == 'application/pdf'
  end

  def validate_file_not_empty
    raise StandardError, 'Empty file' if pdf_source.respond_to?(:empty?) && pdf_source.empty?
  end

  def validate_file_path
    validate_path_presence
    validate_path_existence
    validate_path_file_size
    validate_path_not_empty
    validate_path_readable
  end

  def validate_path_presence
    raise StandardError, 'File path is blank' if pdf_source.blank?
  end

  def validate_path_existence
    raise StandardError, 'File does not exist' unless File.exist?(pdf_source)
  end

  def validate_path_file_size
    raise StandardError, "File too large (max #{self.class::MAX_PDF_SIZE / 1.megabyte}MB)" if File.size(pdf_source) > self.class::MAX_PDF_SIZE
  end

  def validate_path_not_empty
    raise StandardError, 'Empty file' if File.empty?(pdf_source)
  end

  def validate_path_readable
    raise StandardError, 'File is not readable' unless File.readable?(pdf_source)
  end
end