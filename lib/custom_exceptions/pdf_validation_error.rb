require_relative 'pdf_processing_error'

class CustomExceptions::PdfValidationError < CustomExceptions::PdfProcessingError
  def initialize(message = 'PDF validation failed')
    super(message)
  end
end
