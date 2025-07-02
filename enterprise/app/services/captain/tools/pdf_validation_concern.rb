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
    uri = URI.parse(pdf_source)
    raise StandardError, 'Invalid URL format' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    raise StandardError, 'URL too long' if pdf_source.length > 2048
    raise StandardError, 'Invalid URL scheme' unless %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError
    raise StandardError, 'Malformed URL'
  end

  def validate_uploaded_file
    raise StandardError, 'File object is invalid' unless pdf_source.respond_to?(:size) && pdf_source.respond_to?(:content_type)
    raise StandardError, "File too large (max #{self.class::MAX_PDF_SIZE / 1.megabyte}MB)" if pdf_source.size > self.class::MAX_PDF_SIZE
    raise StandardError, 'Invalid file type' unless pdf_source.content_type == 'application/pdf'
    raise StandardError, 'Empty file' if pdf_source.respond_to?(:empty?) && pdf_source.empty?
  end

  def validate_file_path
    raise StandardError, 'File path is blank' if pdf_source.blank?
    raise StandardError, 'File does not exist' unless File.exist?(pdf_source)
    raise StandardError, "File too large (max #{self.class::MAX_PDF_SIZE / 1.megabyte}MB)" if File.size(pdf_source) > self.class::MAX_PDF_SIZE
    raise StandardError, 'Empty file' if File.empty?(pdf_source)
    raise StandardError, 'File is not readable' unless File.readable?(pdf_source)
  end
end