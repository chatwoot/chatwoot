# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentRecordReportRefundParams < ::Stripe::RequestParams
    class Amount < ::Stripe::RequestParams
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_accessor :currency
      # A positive integer representing the amount in the currency's [minor unit](https://stripe.com/docs/currencies#zero-decimal). For example, `100` can represent 1 USD or 100 JPY.
      attr_accessor :value

      def initialize(currency: nil, value: nil)
        @currency = currency
        @value = value
      end
    end

    class ProcessorDetails < ::Stripe::RequestParams
      class Custom < ::Stripe::RequestParams
        # A reference to the external refund. This field must be unique across all refunds.
        attr_accessor :refund_reference

        def initialize(refund_reference: nil)
          @refund_reference = refund_reference
        end
      end
      # Information about the custom processor used to make this refund.
      attr_accessor :custom
      # The type of the processor details. An additional hash is included on processor_details with a name matching this value. It contains additional information specific to the processor.
      attr_accessor :type

      def initialize(custom: nil, type: nil)
        @custom = custom
        @type = type
      end
    end

    class Refunded < ::Stripe::RequestParams
      # When the reported refund completed. Measured in seconds since the Unix epoch.
      attr_accessor :refunded_at

      def initialize(refunded_at: nil)
        @refunded_at = refunded_at
      end
    end
    # A positive integer in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal) representing how much of this payment to refund. Can refund only up to the remaining, unrefunded amount of the payment.
    attr_accessor :amount
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # When the reported refund was initiated. Measured in seconds since the Unix epoch.
    attr_accessor :initiated_at
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # The outcome of the reported refund.
    attr_accessor :outcome
    # Processor information for this refund.
    attr_accessor :processor_details
    # Information about the payment attempt refund.
    attr_accessor :refunded

    def initialize(
      amount: nil,
      expand: nil,
      initiated_at: nil,
      metadata: nil,
      outcome: nil,
      processor_details: nil,
      refunded: nil
    )
      @amount = amount
      @expand = expand
      @initiated_at = initiated_at
      @metadata = metadata
      @outcome = outcome
      @processor_details = processor_details
      @refunded = refunded
    end
  end
end
