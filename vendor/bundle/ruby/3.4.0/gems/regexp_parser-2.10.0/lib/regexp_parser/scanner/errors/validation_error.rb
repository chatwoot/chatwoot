class Regexp::Scanner
  # Base for all scanner validation errors
  class ValidationError < ScannerError
    # Centralizes and unifies the handling of validation related errors.
    def self.for(type, problem, reason = nil)
      types.fetch(type).new(problem, reason)
    end

    def self.types
      @types ||= {
        backref:      InvalidBackrefError,
        group:        InvalidGroupError,
        group_option: InvalidGroupOption,
        posix_class:  UnknownPosixClassError,
        property:     UnknownUnicodePropertyError,
        sequence:     InvalidSequenceError,
      }
    end
  end

  # Invalid sequence format. Used for escape sequences, mainly.
  class InvalidSequenceError < ValidationError
    def initialize(what = 'sequence', where = '')
      super "Invalid #{what} at #{where}"
    end
  end

  # Invalid group. Used for named groups.
  class InvalidGroupError < ValidationError
    def initialize(what, reason)
      super "Invalid #{what}, #{reason}."
    end
  end

  # Invalid groupOption. Used for inline options.
  # TODO: should become InvalidGroupOptionError in v3.0.0 for consistency
  class InvalidGroupOption < ValidationError
    def initialize(option, text)
      super "Invalid group option #{option} in #{text}"
    end
  end

  # Invalid back reference. Used for name a number refs/calls.
  class InvalidBackrefError < ValidationError
    def initialize(what, reason)
      super "Invalid back reference #{what}, #{reason}"
    end
  end

  # The property name was not recognized by the scanner.
  class UnknownUnicodePropertyError < ValidationError
    def initialize(name, _)
      super "Unknown unicode character property name #{name}"
    end
  end

  # The POSIX class name was not recognized by the scanner.
  class UnknownPosixClassError < ValidationError
    def initialize(text, _)
      super "Unknown POSIX class #{text}"
    end
  end
end
