# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Some payment methods have no required amount that a customer must send.
  # Customers can be instructed to send any amount, and it can be made up of
  # multiple transactions. As such, sources can have multiple associated
  # transactions.
  class SourceTransaction < StripeObject
    OBJECT_NAME = "source_transaction"
    def self.object_name
      "source_transaction"
    end

    class AchCreditTransfer < ::Stripe::StripeObject
      # Customer data associated with the transfer.
      attr_reader :customer_data
      # Bank account fingerprint associated with the transfer.
      attr_reader :fingerprint
      # Last 4 digits of the account number associated with the transfer.
      attr_reader :last4
      # Routing number associated with the transfer.
      attr_reader :routing_number

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class ChfCreditTransfer < ::Stripe::StripeObject
      # Reference associated with the transfer.
      attr_reader :reference
      # Sender's country address.
      attr_reader :sender_address_country
      # Sender's line 1 address.
      attr_reader :sender_address_line1
      # Sender's bank account IBAN.
      attr_reader :sender_iban
      # Sender's name.
      attr_reader :sender_name

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class GbpCreditTransfer < ::Stripe::StripeObject
      # Bank account fingerprint associated with the Stripe owned bank account receiving the transfer.
      attr_reader :fingerprint
      # The credit transfer rails the sender used to push this transfer. The possible rails are: Faster Payments, BACS, CHAPS, and wire transfers. Currently only Faster Payments is supported.
      attr_reader :funding_method
      # Last 4 digits of sender account number associated with the transfer.
      attr_reader :last4
      # Sender entered arbitrary information about the transfer.
      attr_reader :reference
      # Sender account number associated with the transfer.
      attr_reader :sender_account_number
      # Sender name associated with the transfer.
      attr_reader :sender_name
      # Sender sort code associated with the transfer.
      attr_reader :sender_sort_code

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PaperCheck < ::Stripe::StripeObject
      # Time at which the deposited funds will be available for use. Measured in seconds since the Unix epoch.
      attr_reader :available_at
      # Comma-separated list of invoice IDs associated with the paper check.
      attr_reader :invoices

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class SepaCreditTransfer < ::Stripe::StripeObject
      # Reference associated with the transfer.
      attr_reader :reference
      # Sender's bank account IBAN.
      attr_reader :sender_iban
      # Sender's name.
      attr_reader :sender_name

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Attribute for field ach_credit_transfer
    attr_reader :ach_credit_transfer
    # A positive integer in the smallest currency unit (that is, 100 cents for $1.00, or 1 for ¥1, Japanese Yen being a zero-decimal currency) representing the amount your customer has pushed to the receiver.
    attr_reader :amount
    # Attribute for field chf_credit_transfer
    attr_reader :chf_credit_transfer
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # Attribute for field gbp_credit_transfer
    attr_reader :gbp_credit_transfer
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Attribute for field paper_check
    attr_reader :paper_check
    # Attribute for field sepa_credit_transfer
    attr_reader :sepa_credit_transfer
    # The ID of the source this transaction is attached to.
    attr_reader :source
    # The status of the transaction, one of `succeeded`, `pending`, or `failed`.
    attr_reader :status
    # The type of source this transaction is attached to.
    attr_reader :type

    def self.inner_class_types
      @inner_class_types = {
        ach_credit_transfer: AchCreditTransfer,
        chf_credit_transfer: ChfCreditTransfer,
        gbp_credit_transfer: GbpCreditTransfer,
        paper_check: PaperCheck,
        sepa_credit_transfer: SepaCreditTransfer,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
