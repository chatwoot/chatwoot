module Sass
  # A deprecation warning that should only be printed once for a given line in a
  # given file.
  #
  # A global Deprecation instance should be created for each type of deprecation
  # warning, and `warn` should be called each time a warning is needed.
  class Deprecation
    @@allow_double_warnings = false

    # Runs a block in which double deprecation warnings for the same location
    # are allowed.
    def self.allow_double_warnings
      old_allow_double_warnings = @@allow_double_warnings
      @@allow_double_warnings = true
      yield
    ensure
      @@allow_double_warnings = old_allow_double_warnings
    end

    def initialize
      # A set of filename, line pairs for which warnings have been emitted.
      @seen = Set.new
    end

    # Prints `message` as a deprecation warning associated with `filename`,
    # `line`, and optionally `column`.
    #
    # This ensures that only one message will be printed for each line of a
    # given file.
    #
    # @overload warn(filename, line, message)
    #   @param filename [String, nil]
    #   @param line [Number]
    #   @param message [String]
    # @overload warn(filename, line, column, message)
    #   @param filename [String, nil]
    #   @param line [Number]
    #   @param column [Number]
    #   @param message [String]
    def warn(filename, line, column_or_message, message = nil)
      return if !@@allow_double_warnings && @seen.add?([filename, line]).nil?
      if message
        column = column_or_message
      else
        message = column_or_message
      end

      location = "line #{line}"
      location << ", column #{column}" if column
      location << " of #{filename}" if filename

      Sass::Util.sass_warn("DEPRECATION WARNING on #{location}:\n#{message}")
    end
  end
end
