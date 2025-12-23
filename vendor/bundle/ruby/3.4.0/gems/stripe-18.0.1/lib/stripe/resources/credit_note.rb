# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Issue a credit note to adjust an invoice's amount after the invoice is finalized.
  #
  # Related guide: [Credit notes](https://stripe.com/docs/billing/invoices/credit-notes)
  class CreditNote < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "credit_note"
    def self.object_name
      "credit_note"
    end

    class DiscountAmount < ::Stripe::StripeObject
      # The amount, in cents (or local equivalent), of the discount.
      attr_reader :amount
      # The discount that was applied to get this discount amount.
      attr_reader :discount

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PretaxCreditAmount < ::Stripe::StripeObject
      # The amount, in cents (or local equivalent), of the pretax credit amount.
      attr_reader :amount
      # The credit balance transaction that was applied to get this pretax credit amount.
      attr_reader :credit_balance_transaction
      # The discount that was applied to get this pretax credit amount.
      attr_reader :discount
      # Type of the pretax credit amount referenced.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Refund < ::Stripe::StripeObject
      class PaymentRecordRefund < ::Stripe::StripeObject
        # ID of the payment record.
        attr_reader :payment_record
        # ID of the refund group.
        attr_reader :refund_group

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Amount of the refund that applies to this credit note, in cents (or local equivalent).
      attr_reader :amount_refunded
      # The PaymentRecord refund details associated with this credit note refund.
      attr_reader :payment_record_refund
      # ID of the refund.
      attr_reader :refund
      # Type of the refund, one of `refund` or `payment_record_refund`.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = { payment_record_refund: PaymentRecordRefund }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class ShippingCost < ::Stripe::StripeObject
      class Tax < ::Stripe::StripeObject
        # Amount of tax applied for this rate.
        attr_reader :amount
        # Tax rates can be applied to [invoices](/invoicing/taxes/tax-rates), [subscriptions](/billing/taxes/tax-rates) and [Checkout Sessions](/payments/checkout/use-manual-tax-rates) to collect tax.
        #
        # Related guide: [Tax rates](/billing/taxes/tax-rates)
        attr_reader :rate
        # The reasoning behind this tax, for example, if the product is tax exempt. The possible values for this field may be extended as new tax rules are supported.
        attr_reader :taxability_reason
        # The amount on which tax is calculated, in cents (or local equivalent).
        attr_reader :taxable_amount

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Total shipping cost before any taxes are applied.
      attr_reader :amount_subtotal
      # Total tax amount applied due to shipping costs. If no tax was applied, defaults to 0.
      attr_reader :amount_tax
      # Total shipping cost after taxes are applied.
      attr_reader :amount_total
      # The ID of the ShippingRate for this invoice.
      attr_reader :shipping_rate
      # The taxes applied to the shipping rate.
      attr_reader :taxes

      def self.inner_class_types
        @inner_class_types = { taxes: Tax }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class TotalTax < ::Stripe::StripeObject
      class TaxRateDetails < ::Stripe::StripeObject
        # Attribute for field tax_rate
        attr_reader :tax_rate

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The amount of the tax, in cents (or local equivalent).
      attr_reader :amount
      # Whether this tax is inclusive or exclusive.
      attr_reader :tax_behavior
      # Additional details about the tax rate. Only present when `type` is `tax_rate_details`.
      attr_reader :tax_rate_details
      # The reasoning behind this tax, for example, if the product is tax exempt. The possible values for this field may be extended as new tax rules are supported.
      attr_reader :taxability_reason
      # The amount on which tax is calculated, in cents (or local equivalent).
      attr_reader :taxable_amount
      # The type of tax information.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = { tax_rate_details: TaxRateDetails }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # The integer amount in cents (or local equivalent) representing the total amount of the credit note, including tax.
    attr_reader :amount
    # This is the sum of all the shipping amounts.
    attr_reader :amount_shipping
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # ID of the customer.
    attr_reader :customer
    # Customer balance transaction related to this credit note.
    attr_reader :customer_balance_transaction
    # The integer amount in cents (or local equivalent) representing the total amount of discount that was credited.
    attr_reader :discount_amount
    # The aggregate amounts calculated per discount for all line items.
    attr_reader :discount_amounts
    # The date when this credit note is in effect. Same as `created` unless overwritten. When defined, this value replaces the system-generated 'Date of issue' printed on the credit note PDF.
    attr_reader :effective_at
    # Unique identifier for the object.
    attr_reader :id
    # ID of the invoice.
    attr_reader :invoice
    # Line items that make up the credit note
    attr_reader :lines
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Customer-facing text that appears on the credit note PDF.
    attr_reader :memo
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # A unique number that identifies this particular credit note and appears on the PDF of the credit note and its associated invoice.
    attr_reader :number
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Amount that was credited outside of Stripe.
    attr_reader :out_of_band_amount
    # The link to download the PDF of the credit note.
    attr_reader :pdf
    # The amount of the credit note that was refunded to the customer, credited to the customer's balance, credited outside of Stripe, or any combination thereof.
    attr_reader :post_payment_amount
    # The amount of the credit note by which the invoice's `amount_remaining` and `amount_due` were reduced.
    attr_reader :pre_payment_amount
    # The pretax credit amounts (ex: discount, credit grants, etc) for all line items.
    attr_reader :pretax_credit_amounts
    # Reason for issuing this credit note, one of `duplicate`, `fraudulent`, `order_change`, or `product_unsatisfactory`
    attr_reader :reason
    # Refunds related to this credit note.
    attr_reader :refunds
    # The details of the cost of shipping, including the ShippingRate applied to the invoice.
    attr_reader :shipping_cost
    # Status of this credit note, one of `issued` or `void`. Learn more about [voiding credit notes](https://stripe.com/docs/billing/invoices/credit-notes#voiding).
    attr_reader :status
    # The integer amount in cents (or local equivalent) representing the amount of the credit note, excluding exclusive tax and invoice level discounts.
    attr_reader :subtotal
    # The integer amount in cents (or local equivalent) representing the amount of the credit note, excluding all tax and invoice level discounts.
    attr_reader :subtotal_excluding_tax
    # The integer amount in cents (or local equivalent) representing the total amount of the credit note, including tax and all discount.
    attr_reader :total
    # The integer amount in cents (or local equivalent) representing the total amount of the credit note, excluding tax, but including discounts.
    attr_reader :total_excluding_tax
    # The aggregate tax information for all line items.
    attr_reader :total_taxes
    # Type of this credit note, one of `pre_payment` or `post_payment`. A `pre_payment` credit note means it was issued when the invoice was open. A `post_payment` credit note means it was issued when the invoice was paid.
    attr_reader :type
    # The time that the credit note was voided.
    attr_reader :voided_at

    # Issue a credit note to adjust the amount of a finalized invoice. A credit note will first reduce the invoice's amount_remaining (and amount_due), but not below zero.
    # This amount is indicated by the credit note's pre_payment_amount. The excess amount is indicated by post_payment_amount, and it can result in any combination of the following:
    #
    #
    # Refunds: create a new refund (using refund_amount) or link existing refunds (using refunds).
    # Customer balance credit: credit the customer's balance (using credit_amount) which will be automatically applied to their next invoice when it's finalized.
    # Outside of Stripe credit: record the amount that is or will be credited outside of Stripe (using out_of_band_amount).
    #
    #
    # The sum of refunds, customer balance credits, and outside of Stripe credits must equal the post_payment_amount.
    #
    # You may issue multiple credit notes for an invoice. Each credit note may increment the invoice's pre_payment_credit_notes_amount,
    # post_payment_credit_notes_amount, or both, depending on the invoice's amount_remaining at the time of credit note creation.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/credit_notes", params: params, opts: opts)
    end

    # Returns a list of credit notes.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/credit_notes", params: params, opts: opts)
    end

    # When retrieving a credit note preview, you'll get a lines property containing the first handful of those items. This URL you can retrieve the full (paginated) list of line items.
    def self.list_preview_line_items(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: "/v1/credit_notes/preview/lines",
        params: params,
        opts: opts
      )
    end

    # Get a preview of a credit note without creating it.
    def self.preview(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: "/v1/credit_notes/preview",
        params: params,
        opts: opts
      )
    end

    # Updates an existing credit note.
    def self.update(id, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/credit_notes/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts
      )
    end

    # Marks a credit note as void. Learn more about [voiding credit notes](https://docs.stripe.com/docs/billing/invoices/credit-notes#voiding).
    def void_credit_note(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/credit_notes/%<id>s/void", { id: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Marks a credit note as void. Learn more about [voiding credit notes](https://docs.stripe.com/docs/billing/invoices/credit-notes#voiding).
    def self.void_credit_note(id, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/credit_notes/%<id>s/void", { id: CGI.escape(id) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {
        discount_amounts: DiscountAmount,
        pretax_credit_amounts: PretaxCreditAmount,
        refunds: Refund,
        shipping_cost: ShippingCost,
        total_taxes: TotalTax,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
