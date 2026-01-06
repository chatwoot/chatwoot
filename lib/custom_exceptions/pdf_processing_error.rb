require_relative 'base'

module CustomExceptions
  class PdfProcessingError < Base
    def initialize(message = 'PDF processing failed')
      super(message)
    end
  end
end
