# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Invoice Line Items represent the individual lines within an [invoice](https://stripe.com/docs/api/invoices) and only exist within the context of an invoice.
  #
  # Each line item is backed by either an [invoice item](https://stripe.com/docs/api/invoiceitems) or a [subscription item](https://stripe.com/docs/api/subscription_items).
  class InvoiceLineItem < APIResource
    include Stripe::APIOperations::Save

    OBJECT_NAME = "line_item"
    def self.object_name
      "line_item"
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

    class Parent < ::Stripe::StripeObject
      class InvoiceItemDetails < ::Stripe::StripeObject
        class ProrationDetails < ::Stripe::StripeObject
          class CreditedItems < ::Stripe::StripeObject
            # Invoice containing the credited invoice line items
            attr_reader :invoice
            # Credited invoice line items
            attr_reader :invoice_line_items

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # For a credit proration `line_item`, the original debit line_items to which the credit proration applies.
          attr_reader :credited_items

          def self.inner_class_types
            @inner_class_types = { credited_items: CreditedItems }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The invoice item that generated this line item
        attr_reader :invoice_item
        # Whether this is a proration
        attr_reader :proration
        # Additional details for proration line items
        attr_reader :proration_details
        # The subscription that the invoice item belongs to
        attr_reader :subscription

        def self.inner_class_types
          @inner_class_types = { proration_details: ProrationDetails }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class SubscriptionItemDetails < ::Stripe::StripeObject
        class ProrationDetails < ::Stripe::StripeObject
          class CreditedItems < ::Stripe::StripeObject
            # Invoice containing the credited invoice line items
            attr_reader :invoice
            # Credited invoice line items
            attr_reader :invoice_line_items

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # For a credit proration `line_item`, the original debit line_items to which the credit proration applies.
          attr_reader :credited_items

          def self.inner_class_types
            @inner_class_types = { credited_items: CreditedItems }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The invoice item that generated this line item
        attr_reader :invoice_item
        # Whether this is a proration
        attr_reader :proration
        # Additional details for proration line items
        attr_reader :proration_details
        # The subscription that the subscription item belongs to
        attr_reader :subscription
        # The subscription item that generated this line item
        attr_reader :subscription_item

        def self.inner_class_types
          @inner_class_types = { proration_details: ProrationDetails }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Details about the invoice item that generated this line item
      attr_reader :invoice_item_details
      # Details about the subscription item that generated this line item
      attr_reader :subscription_item_details
      # The type of parent that generated this line item
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = {
          invoice_item_details: InvoiceItemDetails,
          subscription_item_details: SubscriptionItemDetails,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Period < ::Stripe::StripeObject
      # The end of the period, which must be greater than or equal to the start. This value is inclusive.
      attr_reader :end
      # The start of the period. This value is inclusive.
      attr_reader :start

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

    class Pricing < ::Stripe::StripeObject
      class PriceDetails < ::Stripe::StripeObject
        # The ID of the price this item is associated with.
        attr_reader :price
        # The ID of the product this item is associated with.
        attr_reader :product

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field price_details
      attr_reader :price_details
      # The type of the pricing details.
      attr_reader :type
      # The unit amount (in the `currency` specified) of the item which contains a decimal value with at most 12 decimal places.
      attr_reader :unit_amount_decimal

      def self.inner_class_types
        @inner_class_types = { price_details: PriceDetails }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Tax < ::Stripe::StripeObject
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
    # The amount, in cents (or local equivalent).
    attr_reader :amount
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_reader :description
    # The amount of discount calculated per discount for this line item.
    attr_reader :discount_amounts
    # If true, discounts will apply to this line item. Always false for prorations.
    attr_reader :discountable
    # The discounts applied to the invoice line item. Line item discounts are applied before invoice discounts. Use `expand[]=discounts` to expand each discount.
    attr_reader :discounts
    # Unique identifier for the object.
    attr_reader :id
    # The ID of the invoice that contains this line item.
    attr_reader :invoice
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Note that for line items with `type=subscription`, `metadata` reflects the current metadata from the subscription associated with the line item, unless the invoice line was directly updated with different metadata after creation.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The parent that generated this line item.
    attr_reader :parent
    # Attribute for field period
    attr_reader :period
    # Contains pretax credit amounts (ex: discount, credit grants, etc) that apply to this line item.
    attr_reader :pretax_credit_amounts
    # The pricing information of the line item.
    attr_reader :pricing
    # The quantity of the subscription, if the line item is a subscription or a proration.
    attr_reader :quantity
    # Attribute for field subscription
    attr_reader :subscription
    # The tax information of the line item.
    attr_reader :taxes

    # Updates an invoice's line item. Some fields, such as tax_amounts, only live on the invoice line item,
    # so they can only be updated through this endpoint. Other fields, such as amount, live on both the invoice
    # item and the invoice line item, so updates on this endpoint will propagate to the invoice item as well.
    # Updating an invoice's line item is only possible before the invoice is finalized.
    def self.update(invoice, line_item_id, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/invoices/%<invoice>s/lines/%<line_item_id>s", { invoice: CGI.escape(invoice), line_item_id: CGI.escape(line_item_id) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {
        discount_amounts: DiscountAmount,
        parent: Parent,
        period: Period,
        pretax_credit_amounts: PretaxCreditAmount,
        pricing: Pricing,
        taxes: Tax,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
