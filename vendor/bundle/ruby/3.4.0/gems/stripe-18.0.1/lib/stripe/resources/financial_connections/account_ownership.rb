# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module FinancialConnections
    # Describes a snapshot of the owners of an account at a particular point in time.
    class AccountOwnership < StripeObject
      OBJECT_NAME = "financial_connections.account_ownership"
      def self.object_name
        "financial_connections.account_ownership"
      end

      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Unique identifier for the object.
      attr_reader :id
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # A paginated list of owners for this account.
      attr_reader :owners

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
