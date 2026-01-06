require_relative 'base'

class CustomExceptions::PdfProcessingError < Base
  def initialize(message = 'PDF processing failed')
    super(message)
  end
end
