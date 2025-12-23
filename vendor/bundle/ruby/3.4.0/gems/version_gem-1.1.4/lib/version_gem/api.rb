module VersionGem
  # Public API of this library
  module Api
    # The version number as a string
    #
    # @return [String]
    def to_s
      self::VERSION
    end

    # The major version
    #
    # @return [Integer]
    def major
      @major ||= _to_a[0].to_i
    end

    # The minor version
    #
    # @return [Integer]
    def minor
      @minor ||= _to_a[1].to_i
    end

    # The patch version
    #
    # @return [Integer]
    def patch
      @patch ||= _to_a[2].to_i
    end

    # The pre-release version, if any
    #
    # @return [String, NilClass]
    def pre
      @pre ||= _to_a[3]
    end

    # The version number as a hash
    #
    # @return [Hash]
    def to_h
      @to_h ||= {
        major: major,
        minor: minor,
        patch: patch,
        pre: pre,
      }
    end

    # The version number as an array of cast values
    #
    # @return [Array<[Integer, String, NilClass]>]
    def to_a
      @to_a ||= [major, minor, patch, pre]
    end

    private

    # The version number as an array of strings
    #
    # @return [Array<String>]
    def _to_a
      @_to_a = self::VERSION.split(".")
    end
  end
end
