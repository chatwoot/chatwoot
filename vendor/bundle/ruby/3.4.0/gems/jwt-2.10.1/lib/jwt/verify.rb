# frozen_string_literal: true

require_relative 'error'

module JWT
  # @deprecated This class is deprecated and will be removed in the next major version of ruby-jwt.
  class Verify
    DEFAULTS = { leeway: 0 }.freeze
    METHODS = %w[verify_aud verify_expiration verify_iat verify_iss verify_jti verify_not_before verify_sub verify_required_claims].freeze

    private_constant(:DEFAULTS, :METHODS)
    class << self
      METHODS.each do |method_name|
        define_method(method_name) do |payload, options|
          new(payload, options).send(method_name)
        end
      end

      # @deprecated This method is deprecated and will be removed in the next major version of ruby-jwt.
      def verify_claims(payload, options)
        Deprecations.warning('The ::JWT::Verify.verify_claims method is deprecated and will be removed in the next major version of ruby-jwt')
        ::JWT::Claims.verify!(payload, options)
        true
      end
    end

    # @deprecated This class is deprecated and will be removed in the next major version of ruby-jwt.
    def initialize(payload, options)
      Deprecations.warning('The ::JWT::Verify class is deprecated and will be removed in the next major version of ruby-jwt')
      @payload = payload
      @options = DEFAULTS.merge(options)
    end

    METHODS.each do |method_name|
      define_method(method_name) do
        ::JWT::Claims.verify!(@payload, @options.merge(method_name => true))
      end
    end
  end
end
