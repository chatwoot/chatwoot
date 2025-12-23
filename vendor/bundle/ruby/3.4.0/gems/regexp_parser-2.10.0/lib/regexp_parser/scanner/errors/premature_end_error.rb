class Regexp::Scanner
  # Unexpected end of pattern
  class PrematureEndError < ScannerError
    def initialize(where = '')
      super "Premature end of pattern at #{where}"
    end
  end
end
