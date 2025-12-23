# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Products describe the specific goods or services you offer to your customers.
  # For example, you might offer a Standard and Premium version of your goods or service; each version would be a separate Product.
  # They can be used in conjunction with [Prices](https://stripe.com/docs/api#prices) to configure pricing in Payment Links, Checkout, and Subscriptions.
  #
  # Related guides: [Set up a subscription](https://stripe.com/docs/billing/subscriptions/set-up-subscription),
  # [share a Payment Link](https://stripe.com/docs/payment-links),
  # [accept payments with Checkout](https://stripe.com/docs/payments/accept-a-payment#create-product-prices-upfront),
  # and more about [Products and Prices](https://stripe.com/docs/products-prices/overview)
  class Product < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    extend Stripe::APIOperations::NestedResource
    extend Stripe::APIOperations::Search
    include Stripe::APIOperations::Save

    OBJECT_NAME = "product"
    def self.object_name
      "product"
    end

    nested_resource_class_methods :feature, operations: %i[create retrieve delete list]

    class MarketingFeature < ::Stripe::StripeObject
      # The marketing feature name. Up to 80 characters long.
      attr_reader :name

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PackageDimensions < ::Stripe::StripeObject
      # Height, in inches.
      attr_reader :height
      # Length, in inches.
      attr_reader :length
      # Weight, in ounces.
      attr_reader :weight
      # Width, in inches.
      attr_reader :width

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Whether the product is currently available for purchase.
    attr_reader :active
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # The ID of the [Price](https://stripe.com/docs/api/prices) object that is the default price for this product.
    attr_reader :default_price
    # The product's description, meant to be displayable to the customer. Use this field to optionally store a long form explanation of the product being sold for your own rendering purposes.
    attr_reader :description
    # Unique identifier for the object.
    attr_reader :id
    # A list of up to 8 URLs of images for this product, meant to be displayable to the customer.
    attr_reader :images
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # A list of up to 15 marketing features for this product. These are displayed in [pricing tables](https://stripe.com/docs/payments/checkout/pricing-table).
    attr_reader :marketing_features
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # The product's name, meant to be displayable to the customer.
    attr_reader :name
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The dimensions of this product for shipping purposes.
    attr_reader :package_dimensions
    # Whether this product is shipped (i.e., physical goods).
    attr_reader :shippable
    # Extra information about a product which will appear on your customer's credit card statement. In the case that multiple products are billed at once, the first statement descriptor will be used. Only used for subscription payments.
    attr_reader :statement_descriptor
    # A [tax code](https://stripe.com/docs/tax/tax-categories) ID.
    attr_reader :tax_code
    # The type of the product. The product is either of type `good`, which is eligible for use with Orders and SKUs, or `service`, which is eligible for use with Subscriptions and Plans.
    attr_reader :type
    # A label that represents units of this product. When set, this will be included in customers' receipts, invoices, Checkout, and the customer portal.
    attr_reader :unit_label
    # Time at which the object was last updated. Measured in seconds since the Unix epoch.
    attr_reader :updated
    # A URL of a publicly-accessible webpage for this product.
    attr_reader :url
    # Always true for a deleted object
    attr_reader :deleted

    # Creates a new product object.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/products", params: params, opts: opts)
    end

    # Delete a product. Deleting a product is only possible if it has no prices associated with it. Additionally, deleting a product with type=good is only possible if it has no SKUs associated with it.
    def self.delete(id, params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/products/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts
      )
    end

    # Delete a product. Deleting a product is only possible if it has no prices associated with it. Additionally, deleting a product with type=good is only possible if it has no SKUs associated with it.
    def delete(params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/products/%<id>s", { id: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Returns a list of your products. The products are returned sorted by creation date, with the most recently created products appearing first.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/products", params: params, opts: opts)
    end

    def self.search(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/products/search", params: params, opts: opts)
    end

    def self.search_auto_paging_each(params = {}, opts = {}, &blk)
      search(params, opts).auto_paging_each(&blk)
    end

    # Updates the specific product by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
    def self.update(id, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/products/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {
        marketing_features: MarketingFeature,
        package_dimensions: PackageDimensions,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
