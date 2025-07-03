module Captain::Tools::PdfExtractionService::ErrorHandler
  private

  def extract_pdf_with_error_handling
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

  def success_response(content)
    { success: true, content: content }
  end

  def failure_response(errors)
    { success: false, errors: errors }
  end
end