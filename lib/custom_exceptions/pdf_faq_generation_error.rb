require_relative 'pdf_processing_error'

class CustomExceptions::PdfFaqGenerationError < CustomExceptions::PdfProcessingError
  def initialize(message = 'PDF FAQ generation failed')
    super(message)
  end
end
