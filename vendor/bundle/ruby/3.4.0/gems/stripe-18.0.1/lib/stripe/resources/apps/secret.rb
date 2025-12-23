# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Apps
    # Secret Store is an API that allows Stripe Apps developers to securely persist secrets for use by UI Extensions and app backends.
    #
    # The primary resource in Secret Store is a `secret`. Other apps can't view secrets created by an app. Additionally, secrets are scoped to provide further permission control.
    #
    # All Dashboard users and the app backend share `account` scoped secrets. Use the `account` scope for secrets that don't change per-user, like a third-party API key.
    #
    # A `user` scoped secret is accessible by the app backend and one specific Dashboard user. Use the `user` scope for per-user secrets like per-user OAuth tokens, where different users might have different permissions.
    #
    # Related guide: [Store data between page reloads](https://stripe.com/docs/stripe-apps/store-auth-data-custom-objects)
    class Secret < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List

      OBJECT_NAME = "apps.secret"
      def self.object_name
        "apps.secret"
      end

      class Scope < ::Stripe::StripeObject
        # The secret scope type.
        attr_reader :type
        # The user ID, if type is set to "user"
        attr_reader :user

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # If true, indicates that this secret has been deleted
      attr_reader :deleted
      # The Unix timestamp for the expiry time of the secret, after which the secret deletes.
      attr_reader :expires_at
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # A name for the secret that's unique within the scope.
      attr_reader :name
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The plaintext secret value to be stored.
      attr_reader :payload
      # Attribute for field scope
      attr_reader :scope

      # Create or replace a secret in the secret store.
      def self.create(params = {}, opts = {})
        request_stripe_object(method: :post, path: "/v1/apps/secrets", params: params, opts: opts)
      end

      # Deletes a secret from the secret store by name and scope.
      def self.delete_where(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/apps/secrets/delete",
          params: params,
          opts: opts
        )
      end

      # Finds a secret in the secret store by name and scope.
      def self.find(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/apps/secrets/find",
          params: params,
          opts: opts
        )
      end

      # List all secrets stored on the given scope.
      def self.list(params = {}, opts = {})
        request_stripe_object(method: :get, path: "/v1/apps/secrets", params: params, opts: opts)
      end

      def self.inner_class_types
        @inner_class_types = { scope: Scope }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
