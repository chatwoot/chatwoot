# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    # As a [card issuer](https://stripe.com/docs/issuing), you can dispute transactions that the cardholder does not recognize, suspects to be fraudulent, or has other issues with.
    #
    # Related guide: [Issuing disputes](https://stripe.com/docs/issuing/purchases/disputes)
    class Dispute < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "issuing.dispute"
      def self.object_name
        "issuing.dispute"
      end

      class Evidence < ::Stripe::StripeObject
        class Canceled < ::Stripe::StripeObject
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_reader :additional_documentation
          # Date when order was canceled.
          attr_reader :canceled_at
          # Whether the cardholder was provided with a cancellation policy.
          attr_reader :cancellation_policy_provided
          # Reason for canceling the order.
          attr_reader :cancellation_reason
          # Date when the cardholder expected to receive the product.
          attr_reader :expected_at
          # Explanation of why the cardholder is disputing this transaction.
          attr_reader :explanation
          # Description of the merchandise or service that was purchased.
          attr_reader :product_description
          # Whether the product was a merchandise or service.
          attr_reader :product_type
          # Result of cardholder's attempt to return the product.
          attr_reader :return_status
          # Date when the product was returned or attempted to be returned.
          attr_reader :returned_at

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Duplicate < ::Stripe::StripeObject
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_reader :additional_documentation
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Copy of the card statement showing that the product had already been paid for.
          attr_reader :card_statement
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Copy of the receipt showing that the product had been paid for in cash.
          attr_reader :cash_receipt
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Image of the front and back of the check that was used to pay for the product.
          attr_reader :check_image
          # Explanation of why the cardholder is disputing this transaction.
          attr_reader :explanation
          # Transaction (e.g., ipi_...) that the disputed transaction is a duplicate of. Of the two or more transactions that are copies of each other, this is original undisputed one.
          attr_reader :original_transaction

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Fraudulent < ::Stripe::StripeObject
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_reader :additional_documentation
          # Explanation of why the cardholder is disputing this transaction.
          attr_reader :explanation

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class MerchandiseNotAsDescribed < ::Stripe::StripeObject
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_reader :additional_documentation
          # Explanation of why the cardholder is disputing this transaction.
          attr_reader :explanation
          # Date when the product was received.
          attr_reader :received_at
          # Description of the cardholder's attempt to return the product.
          attr_reader :return_description
          # Result of cardholder's attempt to return the product.
          attr_reader :return_status
          # Date when the product was returned or attempted to be returned.
          attr_reader :returned_at

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class NoValidAuthorization < ::Stripe::StripeObject
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_reader :additional_documentation
          # Explanation of why the cardholder is disputing this transaction.
          attr_reader :explanation

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class NotReceived < ::Stripe::StripeObject
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_reader :additional_documentation
          # Date when the cardholder expected to receive the product.
          attr_reader :expected_at
          # Explanation of why the cardholder is disputing this transaction.
          attr_reader :explanation
          # Description of the merchandise or service that was purchased.
          attr_reader :product_description
          # Whether the product was a merchandise or service.
          attr_reader :product_type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Other < ::Stripe::StripeObject
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_reader :additional_documentation
          # Explanation of why the cardholder is disputing this transaction.
          attr_reader :explanation
          # Description of the merchandise or service that was purchased.
          attr_reader :product_description
          # Whether the product was a merchandise or service.
          attr_reader :product_type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class ServiceNotAsDescribed < ::Stripe::StripeObject
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_reader :additional_documentation
          # Date when order was canceled.
          attr_reader :canceled_at
          # Reason for canceling the order.
          attr_reader :cancellation_reason
          # Explanation of why the cardholder is disputing this transaction.
          attr_reader :explanation
          # Date when the product was received.
          attr_reader :received_at

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field canceled
        attr_reader :canceled
        # Attribute for field duplicate
        attr_reader :duplicate
        # Attribute for field fraudulent
        attr_reader :fraudulent
        # Attribute for field merchandise_not_as_described
        attr_reader :merchandise_not_as_described
        # Attribute for field no_valid_authorization
        attr_reader :no_valid_authorization
        # Attribute for field not_received
        attr_reader :not_received
        # Attribute for field other
        attr_reader :other
        # The reason for filing the dispute. Its value will match the field containing the evidence.
        attr_reader :reason
        # Attribute for field service_not_as_described
        attr_reader :service_not_as_described

        def self.inner_class_types
          @inner_class_types = {
            canceled: Canceled,
            duplicate: Duplicate,
            fraudulent: Fraudulent,
            merchandise_not_as_described: MerchandiseNotAsDescribed,
            no_valid_authorization: NoValidAuthorization,
            not_received: NotReceived,
            other: Other,
            service_not_as_described: ServiceNotAsDescribed,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Treasury < ::Stripe::StripeObject
        # The Treasury [DebitReversal](https://stripe.com/docs/api/treasury/debit_reversals) representing this Issuing dispute
        attr_reader :debit_reversal
        # The Treasury [ReceivedDebit](https://stripe.com/docs/api/treasury/received_debits) that is being disputed.
        attr_reader :received_debit

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Disputed amount in the card's currency and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). Usually the amount of the `transaction`, but can differ (usually because of currency fluctuation).
      attr_reader :amount
      # List of balance transactions associated with the dispute.
      attr_reader :balance_transactions
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # The currency the `transaction` was made in.
      attr_reader :currency
      # Attribute for field evidence
      attr_reader :evidence
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # The enum that describes the dispute loss outcome. If the dispute is not lost, this field will be absent. New enum values may be added in the future, so be sure to handle unknown values.
      attr_reader :loss_reason
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Current status of the dispute.
      attr_reader :status
      # The transaction being disputed.
      attr_reader :transaction
      # [Treasury](https://stripe.com/docs/api/treasury) details related to this dispute if it was created on a [FinancialAccount](/docs/api/treasury/financial_accounts
      attr_reader :treasury

      # Creates an Issuing Dispute object. Individual pieces of evidence within the evidence object are optional at this point. Stripe only validates that required evidence is present during submission. Refer to [Dispute reasons and evidence](https://docs.stripe.com/docs/issuing/purchases/disputes#dispute-reasons-and-evidence) for more details about evidence requirements.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/issuing/disputes",
          params: params,
          opts: opts
        )
      end

      # Returns a list of Issuing Dispute objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/issuing/disputes",
          params: params,
          opts: opts
        )
      end

      # Submits an Issuing Dispute to the card network. Stripe validates that all evidence fields required for the dispute's reason are present. For more details, see [Dispute reasons and evidence](https://docs.stripe.com/docs/issuing/purchases/disputes#dispute-reasons-and-evidence).
      def submit(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/issuing/disputes/%<dispute>s/submit", { dispute: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Submits an Issuing Dispute to the card network. Stripe validates that all evidence fields required for the dispute's reason are present. For more details, see [Dispute reasons and evidence](https://docs.stripe.com/docs/issuing/purchases/disputes#dispute-reasons-and-evidence).
      def self.submit(dispute, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/issuing/disputes/%<dispute>s/submit", { dispute: CGI.escape(dispute) }),
          params: params,
          opts: opts
        )
      end

      # Updates the specified Issuing Dispute object by setting the values of the parameters passed. Any parameters not provided will be left unchanged. Properties on the evidence object can be unset by passing in an empty string.
      def self.update(dispute, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/issuing/disputes/%<dispute>s", { dispute: CGI.escape(dispute) }),
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = { evidence: Evidence, treasury: Treasury }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
