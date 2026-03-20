module CustomExceptions::Audio
  class UnsupportedFormatError < CustomExceptions::Base
    def message
      @data
    end
  end

  class TranscodingError < CustomExceptions::Base
    def message
      @data
    end
  end
end
