require_relative 'pdf_processing_error'

class CustomExceptions::PdfUploadError < CustomExceptions::PdfProcessingError
  def initialize(message = 'PDF upload failed')
    super(message)
  end
end
