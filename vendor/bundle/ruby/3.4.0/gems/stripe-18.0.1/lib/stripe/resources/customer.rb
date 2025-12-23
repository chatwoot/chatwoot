# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # This object represents a customer of your business. Use it to [create recurring charges](https://stripe.com/docs/invoicing/customer), [save payment](https://stripe.com/docs/payments/save-during-payment) and contact information,
  # and track payments that belong to the same customer.
  class Customer < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    extend Stripe::APIOperations::NestedResource
    extend Stripe::APIOperations::Search
    include Stripe::APIOperations::Save

    OBJECT_NAME = "customer"
    def self.object_name
      "customer"
    end

    nested_resource_class_methods :balance_transaction, operations: %i[create retrieve update list]
    nested_resource_class_methods :cash_balance_transaction, operations: %i[retrieve list]
    nested_resource_class_methods :source, operations: %i[create retrieve update delete list]
    nested_resource_class_methods :tax_id, operations: %i[create retrieve delete list]

    class Address < ::Stripe::StripeObject
      # City, district, suburb, town, or village.
      attr_reader :city
      # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
      attr_reader :country
      # Address line 1, such as the street, PO Box, or company name.
      attr_reader :line1
      # Address line 2, such as the apartment, suite, unit, or building.
      attr_reader :line2
      # ZIP or postal code.
      attr_reader :postal_code
      # State, county, province, or region.
      attr_reader :state

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class InvoiceSettings < ::Stripe::StripeObject
      class CustomField < ::Stripe::StripeObject
        # The name of the custom field.
        attr_reader :name
        # The value of the custom field.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class RenderingOptions < ::Stripe::StripeObject
        # How line-item prices and amounts will be displayed with respect to tax on invoice PDFs.
        attr_reader :amount_tax_display
        # ID of the invoice rendering template to be used for this customer's invoices. If set, the template will be used on all invoices for this customer unless a template is set directly on the invoice.
        attr_reader :template

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Default custom fields to be displayed on invoices for this customer.
      attr_reader :custom_fields
      # ID of a payment method that's attached to the customer, to be used as the customer's default payment method for subscriptions and invoices.
      attr_reader :default_payment_method
      # Default footer to be displayed on invoices for this customer.
      attr_reader :footer
      # Default options for invoice PDF rendering for this customer.
      attr_reader :rendering_options

      def self.inner_class_types
        @inner_class_types = { custom_fields: CustomField, rendering_options: RenderingOptions }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Shipping < ::Stripe::StripeObject
      class Address < ::Stripe::StripeObject
        # City, district, suburb, town, or village.
        attr_reader :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_reader :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_reader :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_reader :line2
        # ZIP or postal code.
        attr_reader :postal_code
        # State, county, province, or region.
        attr_reader :state

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field address
      attr_reader :address
      # The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
      attr_reader :carrier
      # Recipient name.
      attr_reader :name
      # Recipient phone (including extension).
      attr_reader :phone
      # The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
      attr_reader :tracking_number

      def self.inner_class_types
        @inner_class_types = { address: Address }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Tax < ::Stripe::StripeObject
      class Location < ::Stripe::StripeObject
        # The identified tax country of the customer.
        attr_reader :country
        # The data source used to infer the customer's location.
        attr_reader :source
        # The identified tax state, county, province, or region of the customer.
        attr_reader :state

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Surfaces if automatic tax computation is possible given the current customer location information.
      attr_reader :automatic_tax
      # A recent IP address of the customer used for tax reporting and tax location inference.
      attr_reader :ip_address
      # The identified tax location of the customer.
      attr_reader :location
      # The tax calculation provider used for location resolution. Defaults to `stripe` when not using a [third-party provider](/tax/third-party-apps).
      attr_reader :provider

      def self.inner_class_types
        @inner_class_types = { location: Location }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # The customer's address.
    attr_reader :address
    # The current balance, if any, that's stored on the customer in their default currency. If negative, the customer has credit to apply to their next invoice. If positive, the customer has an amount owed that's added to their next invoice. The balance only considers amounts that Stripe hasn't successfully applied to any invoice. It doesn't reflect unpaid invoices. This balance is only taken into account after invoices finalize. For multi-currency balances, see [invoice_credit_balance](https://stripe.com/docs/api/customers/object#customer_object-invoice_credit_balance).
    attr_reader :balance
    # The customer's business name.
    attr_reader :business_name
    # The current funds being held by Stripe on behalf of the customer. You can apply these funds towards payment intents when the source is "cash_balance". The `settings[reconciliation_mode]` field describes if these funds apply to these payment intents manually or automatically.
    attr_reader :cash_balance
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Three-letter [ISO code for the currency](https://stripe.com/docs/currencies) the customer can be charged in for recurring billing purposes.
    attr_reader :currency
    # ID of the default payment source for the customer.
    #
    # If you use payment methods created through the PaymentMethods API, see the [invoice_settings.default_payment_method](https://stripe.com/docs/api/customers/object#customer_object-invoice_settings-default_payment_method) field instead.
    attr_reader :default_source
    # Tracks the most recent state change on any invoice belonging to the customer. Paying an invoice or marking it uncollectible via the API will set this field to false. An automatic payment failure or passing the `invoice.due_date` will set this field to `true`.
    #
    # If an invoice becomes uncollectible by [dunning](https://stripe.com/docs/billing/automatic-collection), `delinquent` doesn't reset to `false`.
    #
    # If you care whether the customer has paid their most recent subscription invoice, use `subscription.status` instead. Paying or marking uncollectible any customer invoice regardless of whether it is the latest invoice for a subscription will always set this field to `false`.
    attr_reader :delinquent
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_reader :description
    # Describes the current discount active on the customer, if there is one.
    attr_reader :discount
    # The customer's email address.
    attr_reader :email
    # Unique identifier for the object.
    attr_reader :id
    # The customer's individual name.
    attr_reader :individual_name
    # The current multi-currency balances, if any, that's stored on the customer. If positive in a currency, the customer has a credit to apply to their next invoice denominated in that currency. If negative, the customer has an amount owed that's added to their next invoice denominated in that currency. These balances don't apply to unpaid invoices. They solely track amounts that Stripe hasn't successfully applied to any invoice. Stripe only applies a balance in a specific currency to an invoice after that invoice (which is in the same currency) finalizes.
    attr_reader :invoice_credit_balance
    # The prefix for the customer used to generate unique invoice numbers.
    attr_reader :invoice_prefix
    # Attribute for field invoice_settings
    attr_reader :invoice_settings
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # The customer's full name or business name.
    attr_reader :name
    # The suffix of the customer's next invoice number (for example, 0001). When the account uses account level sequencing, this parameter is ignored in API requests and the field omitted in API responses.
    attr_reader :next_invoice_sequence
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The customer's phone number.
    attr_reader :phone
    # The customer's preferred locales (languages), ordered by preference.
    attr_reader :preferred_locales
    # Mailing and shipping address for the customer. Appears on invoices emailed to this customer.
    attr_reader :shipping
    # The customer's payment sources, if any.
    attr_reader :sources
    # The customer's current subscriptions, if any.
    attr_reader :subscriptions
    # Attribute for field tax
    attr_reader :tax
    # Describes the customer's tax exemption status, which is `none`, `exempt`, or `reverse`. When set to `reverse`, invoice and receipt PDFs include the following text: **"Reverse charge"**.
    attr_reader :tax_exempt
    # The customer's tax IDs.
    attr_reader :tax_ids
    # ID of the test clock that this customer belongs to.
    attr_reader :test_clock
    # Always true for a deleted object
    attr_reader :deleted

    # Creates a new customer object.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/customers", params: params, opts: opts)
    end

    # Retrieve funding instructions for a customer cash balance. If funding instructions do not yet exist for the customer, new
    # funding instructions will be created. If funding instructions have already been created for a given customer, the same
    # funding instructions will be retrieved. In other words, we will return the same funding instructions each time.
    def create_funding_instructions(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/customers/%<customer>s/funding_instructions", { customer: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Retrieve funding instructions for a customer cash balance. If funding instructions do not yet exist for the customer, new
    # funding instructions will be created. If funding instructions have already been created for a given customer, the same
    # funding instructions will be retrieved. In other words, we will return the same funding instructions each time.
    def self.create_funding_instructions(customer, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/customers/%<customer>s/funding_instructions", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts
      )
    end

    # Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer.
    def self.delete(customer, params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/customers/%<customer>s", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts
      )
    end

    # Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer.
    def delete(params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/customers/%<customer>s", { customer: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Removes the currently applied discount on a customer.
    def delete_discount(params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/customers/%<customer>s/discount", { customer: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Removes the currently applied discount on a customer.
    def self.delete_discount(customer, params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/customers/%<customer>s/discount", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts
      )
    end

    # Returns a list of your customers. The customers are returned sorted by creation date, with the most recent customers appearing first.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/customers", params: params, opts: opts)
    end

    # Returns a list of PaymentMethods for a given Customer
    def list_payment_methods(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: format("/v1/customers/%<customer>s/payment_methods", { customer: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Returns a list of PaymentMethods for a given Customer
    def self.list_payment_methods(customer, params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: format("/v1/customers/%<customer>s/payment_methods", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts
      )
    end

    # Retrieves a customer's cash balance.
    def self.retrieve_cash_balance(customer, params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: format("/v1/customers/%<customer>s/cash_balance", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts
      )
    end

    # Retrieves a PaymentMethod object for a given Customer.
    def retrieve_payment_method(payment_method, params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: format("/v1/customers/%<customer>s/payment_methods/%<payment_method>s", { customer: CGI.escape(self["id"]), payment_method: CGI.escape(payment_method) }),
        params: params,
        opts: opts
      )
    end

    # Retrieves a PaymentMethod object for a given Customer.
    def self.retrieve_payment_method(customer, payment_method, params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: format("/v1/customers/%<customer>s/payment_methods/%<payment_method>s", { customer: CGI.escape(customer), payment_method: CGI.escape(payment_method) }),
        params: params,
        opts: opts
      )
    end

    def self.search(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/customers/search", params: params, opts: opts)
    end

    def self.search_auto_paging_each(params = {}, opts = {}, &blk)
      search(params, opts).auto_paging_each(&blk)
    end

    # Updates the specified customer by setting the values of the parameters passed. Any parameters not provided will be left unchanged. For example, if you pass the source parameter, that becomes the customer's active source (e.g., a card) to be used for all charges in the future. When you update a customer to a new valid card source by passing the source parameter: for each of the customer's current subscriptions, if the subscription bills automatically and is in the past_due state, then the latest open invoice for the subscription with automatic collection enabled will be retried. This retry will not count as an automatic retry, and will not affect the next regularly scheduled payment for the invoice. Changing the default_source for a customer will not trigger this behavior.
    #
    # This request accepts mostly the same arguments as the customer creation call.
    def self.update(customer, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/customers/%<customer>s", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts
      )
    end

    # Changes the settings on a customer's cash balance.
    def self.update_cash_balance(customer, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/customers/%<customer>s/cash_balance", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts
      )
    end

    save_nested_resource :source

    # The API request for deleting a card or bank account and for detaching a
    # source object are the same.
    class << self
      alias detach_source delete_source
    end

    def test_helpers
      TestHelpers.new(self)
    end

    class TestHelpers < APIResourceTestHelpers
      RESOURCE_CLASS = Customer
      def self.resource_class
        "Customer"
      end

      # Create an incoming testmode bank transfer
      def self.fund_cash_balance(customer, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/test_helpers/customers/%<customer>s/fund_cash_balance", { customer: CGI.escape(customer) }),
          params: params,
          opts: opts
        )
      end

      # Create an incoming testmode bank transfer
      def fund_cash_balance(params = {}, opts = {})
        @resource.request_stripe_object(
          method: :post,
          path: format("/v1/test_helpers/customers/%<customer>s/fund_cash_balance", { customer: CGI.escape(@resource["id"]) }),
          params: params,
          opts: opts
        )
      end
    end

    def self.inner_class_types
      @inner_class_types = {
        address: Address,
        invoice_settings: InvoiceSettings,
        shipping: Shipping,
        tax: Tax,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
