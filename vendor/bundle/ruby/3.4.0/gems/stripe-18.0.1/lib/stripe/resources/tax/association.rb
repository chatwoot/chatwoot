# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    # A Tax Association exposes the Tax Transactions that Stripe attempted to create on your behalf based on the PaymentIntent input
    class Association < APIResource
      OBJECT_NAME = "tax.association"
      def self.object_name
        "tax.association"
      end

      class TaxTransactionAttempt < ::Stripe::StripeObject
        class Committed < ::Stripe::StripeObject
          # The [Tax Transaction](https://stripe.com/docs/api/tax/transaction/object)
          attr_reader :transaction

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Errored < ::Stripe::StripeObject
          # Details on why we couldn't commit the tax transaction.
          attr_reader :reason

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field committed
        attr_reader :committed
        # Attribute for field errored
        attr_reader :errored
        # The source of the tax transaction attempt. This is either a refund or a payment intent.
        attr_reader :source
        # The status of the transaction attempt. This can be `errored` or `committed`.
        attr_reader :status

        def self.inner_class_types
          @inner_class_types = { committed: Committed, errored: Errored }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The [Tax Calculation](https://stripe.com/docs/api/tax/calculations/object) that was included in PaymentIntent.
      attr_reader :calculation
      # Unique identifier for the object.
      attr_reader :id
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The [PaymentIntent](https://stripe.com/docs/api/payment_intents/object) that this Tax Association is tracking.
      attr_reader :payment_intent
      # Information about the tax transactions linked to this payment intent
      attr_reader :tax_transaction_attempts

      # Finds a tax association object by PaymentIntent id.
      def self.find(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/tax/associations/find",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = { tax_transaction_attempts: TaxTransactionAttempt }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
