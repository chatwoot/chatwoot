# frozen_string_literal: true

require_relative 'decode_configuration'
require_relative 'jwk_configuration'

module JWT
  module Configuration
    # The Container class holds the configuration settings for JWT.
    class Container
      # @!attribute [rw] decode
      #   @return [DecodeConfiguration] the decode configuration.
      # @!attribute [rw] jwk
      #   @return [JwkConfiguration] the JWK configuration.
      # @!attribute [rw] strict_base64_decoding
      #   @return [Boolean] whether strict Base64 decoding is enabled.
      attr_accessor :decode, :jwk, :strict_base64_decoding

      # @!attribute [r] deprecation_warnings
      #   @return [Symbol] the deprecation warnings setting.
      attr_reader :deprecation_warnings

      # Initializes a new Container instance and resets the configuration.
      def initialize
        reset!
      end

      # Resets the configuration to default values.
      #
      # @return [void]
      def reset!
        @decode                 = DecodeConfiguration.new
        @jwk                    = JwkConfiguration.new
        @strict_base64_decoding = false

        self.deprecation_warnings = :once
      end

      DEPRECATION_WARNINGS_VALUES = %i[once warn silent].freeze
      private_constant(:DEPRECATION_WARNINGS_VALUES)
      # Sets the deprecation warnings setting.
      #
      # @param value [Symbol] the deprecation warnings setting. Must be one of `:once`, `:warn`, or `:silent`.
      # @raise [ArgumentError] if the value is not one of the supported values.
      # @return [void]
      def deprecation_warnings=(value)
        raise ArgumentError, "Invalid deprecation_warnings value #{value}. Supported values: #{DEPRECATION_WARNINGS_VALUES}" unless DEPRECATION_WARNINGS_VALUES.include?(value)

        @deprecation_warnings = value
      end
    end
  end
end
