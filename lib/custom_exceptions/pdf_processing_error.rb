require_relative 'base'

class CustomExceptions::PdfProcessingError < CustomExceptions::Base
  def initialize(message = 'PDF processing failed')
    super(message)
  end
end
