module SCSSLint
  # Stores information about a single problem that was detected by a [Linter].
  class Lint
    attr_reader :linter, :filename, :location, :description, :severity

    # @param linter [SCSSLint::Linter]
    # @param filename [String]
    # @param location [SCSSLint::Location]
    # @param description [String]
    # @param severity [Symbol]
    def initialize(linter, filename, location, description, severity = :warning)
      @linter      = linter
      @filename    = filename
      @location    = location
      @description = description
      @severity    = severity
    end

    # @return [Boolean]
    def error?
      severity == :error
    end
  end
end
