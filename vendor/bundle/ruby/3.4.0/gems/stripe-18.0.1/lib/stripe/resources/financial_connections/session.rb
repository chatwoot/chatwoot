# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module FinancialConnections
    # A Financial Connections Session is the secure way to programmatically launch the client-side Stripe.js modal that lets your users link their accounts.
    class Session < APIResource
      extend Stripe::APIOperations::Create

      OBJECT_NAME = "financial_connections.session"
      def self.object_name
        "financial_connections.session"
      end

      class AccountHolder < ::Stripe::StripeObject
        # The ID of the Stripe account this account belongs to. Should only be present if `account_holder.type` is `account`.
        attr_reader :account
        # ID of the Stripe customer this account belongs to. Present if and only if `account_holder.type` is `customer`.
        attr_reader :customer
        # Type of account holder that this account belongs to.
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Filters < ::Stripe::StripeObject
        # Restricts the Session to subcategories of accounts that can be linked. Valid subcategories are: `checking`, `savings`, `mortgage`, `line_of_credit`, `credit_card`.
        attr_reader :account_subcategories
        # List of countries from which to filter accounts.
        attr_reader :countries

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The account holder for whom accounts are collected in this session.
      attr_reader :account_holder
      # The accounts that were collected as part of this Session.
      attr_reader :accounts
      # A value that will be passed to the client to launch the authentication flow.
      attr_reader :client_secret
      # Attribute for field filters
      attr_reader :filters
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Permissions requested for accounts collected during this session.
      attr_reader :permissions
      # Data features requested to be retrieved upon account creation.
      attr_reader :prefetch
      # For webview integrations only. Upon completing OAuth login in the native browser, the user will be redirected to this URL to return to your app.
      attr_reader :return_url

      # To launch the Financial Connections authorization flow, create a Session. The session's client_secret can be used to launch the flow using Stripe.js.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/financial_connections/sessions",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = { account_holder: AccountHolder, filters: Filters }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
