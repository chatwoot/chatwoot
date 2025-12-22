module CustomExceptions
  class PdfProcessingError < Base
    def initialize(message = 'PDF processing failed')
      super(message)
    end
  end

  class PdfUploadError < PdfProcessingError
    def initialize(message = 'PDF upload failed')
      super(message)
    end
  end

  class PdfValidationError < PdfProcessingError
    def initialize(message = 'PDF validation failed')
      super(message)
    end
  end

  class PdfFaqGenerationError < PdfProcessingError
    def initialize(message = 'PDF FAQ generation failed')
      super(message)
    end
  end
end
