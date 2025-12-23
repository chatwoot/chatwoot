require_relative '../../../regexp_parser/error'

class Regexp::Scanner
  # General scanner error (catch all)
  class ScannerError < Regexp::Parser::Error; end
end
