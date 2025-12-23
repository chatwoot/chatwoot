# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Radar
    # An early fraud warning indicates that the card issuer has notified us that a
    # charge may be fraudulent.
    #
    # Related guide: [Early fraud warnings](https://stripe.com/docs/disputes/measuring#early-fraud-warnings)
    class EarlyFraudWarning < APIResource
      extend Stripe::APIOperations::List

      OBJECT_NAME = "radar.early_fraud_warning"
      def self.object_name
        "radar.early_fraud_warning"
      end

      # An EFW is actionable if it has not received a dispute and has not been fully refunded. You may wish to proactively refund a charge that receives an EFW, in order to avoid receiving a dispute later.
      attr_reader :actionable
      # ID of the charge this early fraud warning is for, optionally expanded.
      attr_reader :charge
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # The type of fraud labelled by the issuer. One of `card_never_received`, `fraudulent_card_application`, `made_with_counterfeit_card`, `made_with_lost_card`, `made_with_stolen_card`, `misc`, `unauthorized_use_of_card`.
      attr_reader :fraud_type
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # ID of the Payment Intent this early fraud warning is for, optionally expanded.
      attr_reader :payment_intent

      # Returns a list of early fraud warnings.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/radar/early_fraud_warnings",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
