module Captain::Tools::PdfValidationConcern
  extend ActiveSupport::Concern

  private

  def validate_pdf_source
    case determine_source_type
    when :url
      validate_url_format
    when :uploaded_file
      validate_file_type_and_size
    when :active_storage_attachment
      validate_attachment
    end

    { success: true }
  rescue StandardError => e
    Rails.logger.error "PDF validation failed: #{e.message}"
    { success: false, errors: [e.message] }
  end

  def validate_url_format
    URI.parse(pdf_source)
  end

  def validate_file_type_and_size
    raise StandardError, 'Invalid file type' unless pdf_source.content_type == 'application/pdf'
    raise StandardError, 'File too large' if pdf_source.size > 25.megabytes
  end

  def validate_attachment
    raise StandardError, 'No file attached' unless pdf_source.attached?
    raise StandardError, 'Invalid file type' unless pdf_source.content_type == 'application/pdf'
  end
end