# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Apps
    class SecretCreateParams < ::Stripe::RequestParams
      class Scope < ::Stripe::RequestParams
        # The secret scope type.
        attr_accessor :type
        # The user ID. This field is required if `type` is set to `user`, and should not be provided if `type` is set to `account`.
        attr_accessor :user

        def initialize(type: nil, user: nil)
          @type = type
          @user = user
        end
      end
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The Unix timestamp for the expiry time of the secret, after which the secret deletes.
      attr_accessor :expires_at
      # A name for the secret that's unique within the scope.
      attr_accessor :name
      # The plaintext secret value to be stored.
      attr_accessor :payload
      # Specifies the scoping of the secret. Requests originating from UI extensions can only access account-scoped secrets or secrets scoped to their own user.
      attr_accessor :scope

      def initialize(expand: nil, expires_at: nil, name: nil, payload: nil, scope: nil)
        @expand = expand
        @expires_at = expires_at
        @name = name
        @payload = payload
        @scope = scope
      end
    end
  end
end
