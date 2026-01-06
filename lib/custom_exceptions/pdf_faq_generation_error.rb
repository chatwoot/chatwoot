require_relative 'pdf_processing_error'

class CustomExceptions::PdfFaqGenerationError < PdfProcessingError
  def initialize(message = 'PDF FAQ generation failed')
    super(message)
  end
end
