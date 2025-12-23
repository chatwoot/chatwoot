# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Invoice Items represent the component lines of an [invoice](https://stripe.com/docs/api/invoices). When you create an invoice item with an `invoice` field, it is attached to the specified invoice and included as [an invoice line item](https://stripe.com/docs/api/invoices/line_item) within [invoice.lines](https://stripe.com/docs/api/invoices/object#invoice_object-lines).
  #
  # Invoice Items can be created before you are ready to actually send the invoice. This can be particularly useful when combined
  # with a [subscription](https://stripe.com/docs/api/subscriptions). Sometimes you want to add a charge or credit to a customer, but actually charge
  # or credit the customer's card only at the end of a regular billing cycle. This is useful for combining several charges
  # (to minimize per-transaction fees), or for having Stripe tabulate your usage-based billing totals.
  #
  # Related guides: [Integrate with the Invoicing API](https://stripe.com/docs/invoicing/integration), [Subscription Invoices](https://stripe.com/docs/billing/invoices/subscription#adding-upcoming-invoice-items).
  class InvoiceItem < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "invoiceitem"
    def self.object_name
      "invoiceitem"
    end

    class Parent < ::Stripe::StripeObject
      class SubscriptionDetails < ::Stripe::StripeObject
        # The subscription that generated this invoice item
        attr_reader :subscription
        # The subscription item that generated this invoice item
        attr_reader :subscription_item

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Details about the subscription that generated this invoice item
      attr_reader :subscription_details
      # The type of parent that generated this invoice item
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = { subscription_details: SubscriptionDetails }
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

    class ProrationDetails < ::Stripe::StripeObject
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
      # Discount amounts applied when the proration was created.
      attr_reader :discount_amounts

      def self.inner_class_types
        @inner_class_types = { discount_amounts: DiscountAmount }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Amount (in the `currency` specified) of the invoice item. This should always be equal to `unit_amount * quantity`.
    attr_reader :amount
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # The ID of the customer who will be billed when this invoice item is billed.
    attr_reader :customer
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :date
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_reader :description
    # If true, discounts will apply to this invoice item. Always false for prorations.
    attr_reader :discountable
    # The discounts which apply to the invoice item. Item discounts are applied before invoice discounts. Use `expand[]=discounts` to expand each discount.
    attr_reader :discounts
    # Unique identifier for the object.
    attr_reader :id
    # The ID of the invoice this invoice item belongs to.
    attr_reader :invoice
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # The amount after discounts, but before credits and taxes. This field is `null` for `discountable=true` items.
    attr_reader :net_amount
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The parent that generated this invoice item.
    attr_reader :parent
    # Attribute for field period
    attr_reader :period
    # The pricing information of the invoice item.
    attr_reader :pricing
    # Whether the invoice item was created automatically as a proration adjustment when the customer switched plans.
    attr_reader :proration
    # Attribute for field proration_details
    attr_reader :proration_details
    # Quantity of units for the invoice item. If the invoice item is a proration, the quantity of the subscription that the proration was computed for.
    attr_reader :quantity
    # The tax rates which apply to the invoice item. When set, the `default_tax_rates` on the invoice do not apply to this invoice item.
    attr_reader :tax_rates
    # ID of the test clock this invoice item belongs to.
    attr_reader :test_clock
    # Always true for a deleted object
    attr_reader :deleted

    # Creates an item to be added to a draft invoice (up to 250 items per invoice). If no invoice is specified, the item will be on the next invoice created for the customer specified.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/invoiceitems", params: params, opts: opts)
    end

    # Deletes an invoice item, removing it from an invoice. Deleting invoice items is only possible when they're not attached to invoices, or if it's attached to a draft invoice.
    def self.delete(invoiceitem, params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/invoiceitems/%<invoiceitem>s", { invoiceitem: CGI.escape(invoiceitem) }),
        params: params,
        opts: opts
      )
    end

    # Deletes an invoice item, removing it from an invoice. Deleting invoice items is only possible when they're not attached to invoices, or if it's attached to a draft invoice.
    def delete(params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/invoiceitems/%<invoiceitem>s", { invoiceitem: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Returns a list of your invoice items. Invoice items are returned sorted by creation date, with the most recently created invoice items appearing first.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/invoiceitems", params: params, opts: opts)
    end

    # Updates the amount or description of an invoice item on an upcoming invoice. Updating an invoice item is only possible before the invoice it's attached to is closed.
    def self.update(invoiceitem, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/invoiceitems/%<invoiceitem>s", { invoiceitem: CGI.escape(invoiceitem) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {
        parent: Parent,
        period: Period,
        pricing: Pricing,
        proration_details: ProrationDetails,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
