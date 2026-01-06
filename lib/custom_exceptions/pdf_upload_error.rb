class CustomExceptions::PdfUploadError < CustomExceptions::PdfProcessingError
  def initialize(message = 'PDF upload failed')
    super(message)
  end
end
