# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module FinancialConnections
    # Describes an owner of an account.
    class AccountOwner < StripeObject
      OBJECT_NAME = "financial_connections.account_owner"
      def self.object_name
        "financial_connections.account_owner"
      end

      # The email address of the owner.
      attr_reader :email
      # Unique identifier for the object.
      attr_reader :id
      # The full name of the owner.
      attr_reader :name
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The ownership object that this owner belongs to.
      attr_reader :ownership
      # The raw phone number of the owner.
      attr_reader :phone
      # The raw physical address of the owner.
      attr_reader :raw_address
      # The timestamp of the refresh that updated this owner.
      attr_reader :refreshed_at

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
