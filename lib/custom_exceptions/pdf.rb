module CustomExceptions::Pdf
  class UploadError < CustomExceptions::Base
    def initialize(message = 'PDF upload failed')
      super(message)
    end
  end

  class ValidationError < CustomExceptions::Base
    def initialize(message = 'PDF validation failed')
      super(message)
    end
  end

  class FaqGenerationError < CustomExceptions::Base
    def initialize(message = 'PDF FAQ generation failed')
      super(message)
    end
  end
end
