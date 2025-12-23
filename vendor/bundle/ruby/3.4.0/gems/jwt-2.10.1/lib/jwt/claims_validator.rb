# frozen_string_literal: true

module JWT
  # @deprecated Use `Claims.verify_payload!` directly instead.
  class ClaimsValidator
    # @deprecated Use `Claims.verify_payload!` directly instead.
    def initialize(payload)
      Deprecations.warning('The ::JWT::ClaimsValidator class is deprecated and will be removed in the next major version of ruby-jwt')
      @payload = payload
    end

    # @deprecated Use `Claims.verify_payload!` directly instead.
    def validate!
      Claims.verify_payload!(@payload, :numeric)
      true
    end
  end
end
