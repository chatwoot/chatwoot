# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CreditNotePreviewParams < ::Stripe::RequestParams
    class Line < ::Stripe::RequestParams
      class TaxAmount < ::Stripe::RequestParams
        # The amount, in cents (or local equivalent), of the tax.
        attr_accessor :amount
        # The id of the tax rate for this tax amount. The tax rate must have been automatically created by Stripe.
        attr_accessor :tax_rate
        # The amount on which tax is calculated, in cents (or local equivalent).
        attr_accessor :taxable_amount

        def initialize(amount: nil, tax_rate: nil, taxable_amount: nil)
          @amount = amount
          @tax_rate = tax_rate
          @taxable_amount = taxable_amount
        end
      end
      # The line item amount to credit. Only valid when `type` is `invoice_line_item`. If invoice is set up with `automatic_tax[enabled]=true`, this amount is tax exclusive
      attr_accessor :amount
      # The description of the credit note line item. Only valid when the `type` is `custom_line_item`.
      attr_accessor :description
      # The invoice line item to credit. Only valid when the `type` is `invoice_line_item`.
      attr_accessor :invoice_line_item
      # The line item quantity to credit.
      attr_accessor :quantity
      # A list of up to 10 tax amounts for the credit note line item. Cannot be mixed with `tax_rates`.
      attr_accessor :tax_amounts
      # The tax rates which apply to the credit note line item. Only valid when the `type` is `custom_line_item` and cannot be mixed with `tax_amounts`.
      attr_accessor :tax_rates
      # Type of the credit note line item, one of `invoice_line_item` or `custom_line_item`
      attr_accessor :type
      # The integer unit amount in cents (or local equivalent) of the credit note line item. This `unit_amount` will be multiplied by the quantity to get the full amount to credit for this line item. Only valid when `type` is `custom_line_item`.
      attr_accessor :unit_amount
      # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
      attr_accessor :unit_amount_decimal

      def initialize(
        amount: nil,
        description: nil,
        invoice_line_item: nil,
        quantity: nil,
        tax_amounts: nil,
        tax_rates: nil,
        type: nil,
        unit_amount: nil,
        unit_amount_decimal: nil
      )
        @amount = amount
        @description = description
        @invoice_line_item = invoice_line_item
        @quantity = quantity
        @tax_amounts = tax_amounts
        @tax_rates = tax_rates
        @type = type
        @unit_amount = unit_amount
        @unit_amount_decimal = unit_amount_decimal
      end
    end

    class Refund < ::Stripe::RequestParams
      class PaymentRecordRefund < ::Stripe::RequestParams
        # The ID of the PaymentRecord with the refund to link to this credit note.
        attr_accessor :payment_record
        # The PaymentRecord refund group to link to this credit note. For refunds processed off-Stripe, this will correspond to the `processor_details.custom.refund_reference` field provided when reporting the refund on the PaymentRecord.
        attr_accessor :refund_group

        def initialize(payment_record: nil, refund_group: nil)
          @payment_record = payment_record
          @refund_group = refund_group
        end
      end
      # Amount of the refund that applies to this credit note, in cents (or local equivalent). Defaults to the entire refund amount.
      attr_accessor :amount_refunded
      # The PaymentRecord refund details to link to this credit note. Required when `type` is `payment_record_refund`.
      attr_accessor :payment_record_refund
      # ID of an existing refund to link this credit note to. Required when `type` is `refund`.
      attr_accessor :refund
      # Type of the refund, one of `refund` or `payment_record_refund`. Defaults to `refund`.
      attr_accessor :type

      def initialize(amount_refunded: nil, payment_record_refund: nil, refund: nil, type: nil)
        @amount_refunded = amount_refunded
        @payment_record_refund = payment_record_refund
        @refund = refund
        @type = type
      end
    end

    class ShippingCost < ::Stripe::RequestParams
      # The ID of the shipping rate to use for this order.
      attr_accessor :shipping_rate

      def initialize(shipping_rate: nil)
        @shipping_rate = shipping_rate
      end
    end
    # The integer amount in cents (or local equivalent) representing the total amount of the credit note. One of `amount`, `lines`, or `shipping_cost` must be provided.
    attr_accessor :amount
    # The integer amount in cents (or local equivalent) representing the amount to credit the customer's balance, which will be automatically applied to their next invoice.
    attr_accessor :credit_amount
    # The date when this credit note is in effect. Same as `created` unless overwritten. When defined, this value replaces the system-generated 'Date of issue' printed on the credit note PDF.
    attr_accessor :effective_at
    # Type of email to send to the customer, one of `credit_note` or `none` and the default is `credit_note`.
    attr_accessor :email_type
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # ID of the invoice.
    attr_accessor :invoice
    # Line items that make up the credit note. One of `amount`, `lines`, or `shipping_cost` must be provided.
    attr_accessor :lines
    # The credit note's memo appears on the credit note PDF.
    attr_accessor :memo
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # The integer amount in cents (or local equivalent) representing the amount that is credited outside of Stripe.
    attr_accessor :out_of_band_amount
    # Reason for issuing this credit note, one of `duplicate`, `fraudulent`, `order_change`, or `product_unsatisfactory`
    attr_accessor :reason
    # The integer amount in cents (or local equivalent) representing the amount to refund. If set, a refund will be created for the charge associated with the invoice.
    attr_accessor :refund_amount
    # Refunds to link to this credit note.
    attr_accessor :refunds
    # When shipping_cost contains the shipping_rate from the invoice, the shipping_cost is included in the credit note. One of `amount`, `lines`, or `shipping_cost` must be provided.
    attr_accessor :shipping_cost

    def initialize(
      amount: nil,
      credit_amount: nil,
      effective_at: nil,
      email_type: nil,
      expand: nil,
      invoice: nil,
      lines: nil,
      memo: nil,
      metadata: nil,
      out_of_band_amount: nil,
      reason: nil,
      refund_amount: nil,
      refunds: nil,
      shipping_cost: nil
    )
      @amount = amount
      @credit_amount = credit_amount
      @effective_at = effective_at
      @email_type = email_type
      @expand = expand
      @invoice = invoice
      @lines = lines
      @memo = memo
      @metadata = metadata
      @out_of_band_amount = out_of_band_amount
      @reason = reason
      @refund_amount = refund_amount
      @refunds = refunds
      @shipping_cost = shipping_cost
    end
  end
end
