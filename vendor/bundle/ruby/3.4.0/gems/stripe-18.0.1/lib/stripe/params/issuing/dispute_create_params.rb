# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class DisputeCreateParams < ::Stripe::RequestParams
      class Evidence < ::Stripe::RequestParams
        class Canceled < ::Stripe::RequestParams
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_accessor :additional_documentation
          # Date when order was canceled.
          attr_accessor :canceled_at
          # Whether the cardholder was provided with a cancellation policy.
          attr_accessor :cancellation_policy_provided
          # Reason for canceling the order.
          attr_accessor :cancellation_reason
          # Date when the cardholder expected to receive the product.
          attr_accessor :expected_at
          # Explanation of why the cardholder is disputing this transaction.
          attr_accessor :explanation
          # Description of the merchandise or service that was purchased.
          attr_accessor :product_description
          # Whether the product was a merchandise or service.
          attr_accessor :product_type
          # Result of cardholder's attempt to return the product.
          attr_accessor :return_status
          # Date when the product was returned or attempted to be returned.
          attr_accessor :returned_at

          def initialize(
            additional_documentation: nil,
            canceled_at: nil,
            cancellation_policy_provided: nil,
            cancellation_reason: nil,
            expected_at: nil,
            explanation: nil,
            product_description: nil,
            product_type: nil,
            return_status: nil,
            returned_at: nil
          )
            @additional_documentation = additional_documentation
            @canceled_at = canceled_at
            @cancellation_policy_provided = cancellation_policy_provided
            @cancellation_reason = cancellation_reason
            @expected_at = expected_at
            @explanation = explanation
            @product_description = product_description
            @product_type = product_type
            @return_status = return_status
            @returned_at = returned_at
          end
        end

        class Duplicate < ::Stripe::RequestParams
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_accessor :additional_documentation
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Copy of the card statement showing that the product had already been paid for.
          attr_accessor :card_statement
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Copy of the receipt showing that the product had been paid for in cash.
          attr_accessor :cash_receipt
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Image of the front and back of the check that was used to pay for the product.
          attr_accessor :check_image
          # Explanation of why the cardholder is disputing this transaction.
          attr_accessor :explanation
          # Transaction (e.g., ipi_...) that the disputed transaction is a duplicate of. Of the two or more transactions that are copies of each other, this is original undisputed one.
          attr_accessor :original_transaction

          def initialize(
            additional_documentation: nil,
            card_statement: nil,
            cash_receipt: nil,
            check_image: nil,
            explanation: nil,
            original_transaction: nil
          )
            @additional_documentation = additional_documentation
            @card_statement = card_statement
            @cash_receipt = cash_receipt
            @check_image = check_image
            @explanation = explanation
            @original_transaction = original_transaction
          end
        end

        class Fraudulent < ::Stripe::RequestParams
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_accessor :additional_documentation
          # Explanation of why the cardholder is disputing this transaction.
          attr_accessor :explanation

          def initialize(additional_documentation: nil, explanation: nil)
            @additional_documentation = additional_documentation
            @explanation = explanation
          end
        end

        class MerchandiseNotAsDescribed < ::Stripe::RequestParams
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_accessor :additional_documentation
          # Explanation of why the cardholder is disputing this transaction.
          attr_accessor :explanation
          # Date when the product was received.
          attr_accessor :received_at
          # Description of the cardholder's attempt to return the product.
          attr_accessor :return_description
          # Result of cardholder's attempt to return the product.
          attr_accessor :return_status
          # Date when the product was returned or attempted to be returned.
          attr_accessor :returned_at

          def initialize(
            additional_documentation: nil,
            explanation: nil,
            received_at: nil,
            return_description: nil,
            return_status: nil,
            returned_at: nil
          )
            @additional_documentation = additional_documentation
            @explanation = explanation
            @received_at = received_at
            @return_description = return_description
            @return_status = return_status
            @returned_at = returned_at
          end
        end

        class NoValidAuthorization < ::Stripe::RequestParams
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_accessor :additional_documentation
          # Explanation of why the cardholder is disputing this transaction.
          attr_accessor :explanation

          def initialize(additional_documentation: nil, explanation: nil)
            @additional_documentation = additional_documentation
            @explanation = explanation
          end
        end

        class NotReceived < ::Stripe::RequestParams
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_accessor :additional_documentation
          # Date when the cardholder expected to receive the product.
          attr_accessor :expected_at
          # Explanation of why the cardholder is disputing this transaction.
          attr_accessor :explanation
          # Description of the merchandise or service that was purchased.
          attr_accessor :product_description
          # Whether the product was a merchandise or service.
          attr_accessor :product_type

          def initialize(
            additional_documentation: nil,
            expected_at: nil,
            explanation: nil,
            product_description: nil,
            product_type: nil
          )
            @additional_documentation = additional_documentation
            @expected_at = expected_at
            @explanation = explanation
            @product_description = product_description
            @product_type = product_type
          end
        end

        class Other < ::Stripe::RequestParams
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_accessor :additional_documentation
          # Explanation of why the cardholder is disputing this transaction.
          attr_accessor :explanation
          # Description of the merchandise or service that was purchased.
          attr_accessor :product_description
          # Whether the product was a merchandise or service.
          attr_accessor :product_type

          def initialize(
            additional_documentation: nil,
            explanation: nil,
            product_description: nil,
            product_type: nil
          )
            @additional_documentation = additional_documentation
            @explanation = explanation
            @product_description = product_description
            @product_type = product_type
          end
        end

        class ServiceNotAsDescribed < ::Stripe::RequestParams
          # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) Additional documentation supporting the dispute.
          attr_accessor :additional_documentation
          # Date when order was canceled.
          attr_accessor :canceled_at
          # Reason for canceling the order.
          attr_accessor :cancellation_reason
          # Explanation of why the cardholder is disputing this transaction.
          attr_accessor :explanation
          # Date when the product was received.
          attr_accessor :received_at

          def initialize(
            additional_documentation: nil,
            canceled_at: nil,
            cancellation_reason: nil,
            explanation: nil,
            received_at: nil
          )
            @additional_documentation = additional_documentation
            @canceled_at = canceled_at
            @cancellation_reason = cancellation_reason
            @explanation = explanation
            @received_at = received_at
          end
        end
        # Evidence provided when `reason` is 'canceled'.
        attr_accessor :canceled
        # Evidence provided when `reason` is 'duplicate'.
        attr_accessor :duplicate
        # Evidence provided when `reason` is 'fraudulent'.
        attr_accessor :fraudulent
        # Evidence provided when `reason` is 'merchandise_not_as_described'.
        attr_accessor :merchandise_not_as_described
        # Evidence provided when `reason` is 'no_valid_authorization'.
        attr_accessor :no_valid_authorization
        # Evidence provided when `reason` is 'not_received'.
        attr_accessor :not_received
        # Evidence provided when `reason` is 'other'.
        attr_accessor :other
        # The reason for filing the dispute. The evidence should be submitted in the field of the same name.
        attr_accessor :reason
        # Evidence provided when `reason` is 'service_not_as_described'.
        attr_accessor :service_not_as_described

        def initialize(
          canceled: nil,
          duplicate: nil,
          fraudulent: nil,
          merchandise_not_as_described: nil,
          no_valid_authorization: nil,
          not_received: nil,
          other: nil,
          reason: nil,
          service_not_as_described: nil
        )
          @canceled = canceled
          @duplicate = duplicate
          @fraudulent = fraudulent
          @merchandise_not_as_described = merchandise_not_as_described
          @no_valid_authorization = no_valid_authorization
          @not_received = not_received
          @other = other
          @reason = reason
          @service_not_as_described = service_not_as_described
        end
      end

      class Treasury < ::Stripe::RequestParams
        # The ID of the ReceivedDebit to initiate an Issuings dispute for.
        attr_accessor :received_debit

        def initialize(received_debit: nil)
          @received_debit = received_debit
        end
      end
      # The dispute amount in the card's currency and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). If not set, defaults to the full transaction amount.
      attr_accessor :amount
      # Evidence provided for the dispute.
      attr_accessor :evidence
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The ID of the issuing transaction to create a dispute for. For transaction on Treasury FinancialAccounts, use `treasury.received_debit`.
      attr_accessor :transaction
      # Params for disputes related to Treasury FinancialAccounts
      attr_accessor :treasury

      def initialize(
        amount: nil,
        evidence: nil,
        expand: nil,
        metadata: nil,
        transaction: nil,
        treasury: nil
      )
        @amount = amount
        @evidence = evidence
        @expand = expand
        @metadata = metadata
        @transaction = transaction
        @treasury = treasury
      end
    end
  end
end
