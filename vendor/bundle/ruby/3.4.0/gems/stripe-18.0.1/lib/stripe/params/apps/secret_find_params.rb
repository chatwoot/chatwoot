# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Apps
    class SecretFindParams < ::Stripe::RequestParams
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
      # A name for the secret that's unique within the scope.
      attr_accessor :name
      # Specifies the scoping of the secret. Requests originating from UI extensions can only access account-scoped secrets or secrets scoped to their own user.
      attr_accessor :scope

      def initialize(expand: nil, name: nil, scope: nil)
        @expand = expand
        @name = name
        @scope = scope
      end
    end
  end
end
