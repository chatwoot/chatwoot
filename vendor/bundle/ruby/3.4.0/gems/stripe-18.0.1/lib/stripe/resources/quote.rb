# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # A Quote is a way to model prices that you'd like to provide to a customer.
  # Once accepted, it will automatically create an invoice, subscription or subscription schedule.
  class Quote < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "quote"
    def self.object_name
      "quote"
    end

    class AutomaticTax < ::Stripe::StripeObject
      class Liability < ::Stripe::StripeObject
        # The connected account being referenced when `type` is `account`.
        attr_reader :account
        # Type of the account referenced.
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Automatically calculate taxes
      attr_reader :enabled
      # The account that's liable for tax. If set, the business address and tax registrations required to perform the tax calculation are loaded from this account. The tax transaction is returned in the report of the connected account.
      attr_reader :liability
      # The tax provider powering automatic tax.
      attr_reader :provider
      # The status of the most recent automated tax calculation for this quote.
      attr_reader :status

      def self.inner_class_types
        @inner_class_types = { liability: Liability }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Computed < ::Stripe::StripeObject
      class Recurring < ::Stripe::StripeObject
        class TotalDetails < ::Stripe::StripeObject
          class Breakdown < ::Stripe::StripeObject
            class Discount < ::Stripe::StripeObject
              # The amount discounted.
              attr_reader :amount
              # A discount represents the actual application of a [coupon](https://stripe.com/docs/api#coupons) or [promotion code](https://stripe.com/docs/api#promotion_codes).
              # It contains information about when the discount began, when it will end, and what it is applied to.
              #
              # Related guide: [Applying discounts to subscriptions](https://stripe.com/docs/billing/subscriptions/discounts)
              attr_reader :discount

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end

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
            # The aggregated discounts.
            attr_reader :discounts
            # The aggregated tax amounts by rate.
            attr_reader :taxes

            def self.inner_class_types
              @inner_class_types = { discounts: Discount, taxes: Tax }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # This is the sum of all the discounts.
          attr_reader :amount_discount
          # This is the sum of all the shipping amounts.
          attr_reader :amount_shipping
          # This is the sum of all the tax amounts.
          attr_reader :amount_tax
          # Attribute for field breakdown
          attr_reader :breakdown

          def self.inner_class_types
            @inner_class_types = { breakdown: Breakdown }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Total before any discounts or taxes are applied.
        attr_reader :amount_subtotal
        # Total after discounts and taxes are applied.
        attr_reader :amount_total
        # The frequency at which a subscription is billed. One of `day`, `week`, `month` or `year`.
        attr_reader :interval
        # The number of intervals (specified in the `interval` attribute) between subscription billings. For example, `interval=month` and `interval_count=3` bills every 3 months.
        attr_reader :interval_count
        # Attribute for field total_details
        attr_reader :total_details

        def self.inner_class_types
          @inner_class_types = { total_details: TotalDetails }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Upfront < ::Stripe::StripeObject
        class TotalDetails < ::Stripe::StripeObject
          class Breakdown < ::Stripe::StripeObject
            class Discount < ::Stripe::StripeObject
              # The amount discounted.
              attr_reader :amount
              # A discount represents the actual application of a [coupon](https://stripe.com/docs/api#coupons) or [promotion code](https://stripe.com/docs/api#promotion_codes).
              # It contains information about when the discount began, when it will end, and what it is applied to.
              #
              # Related guide: [Applying discounts to subscriptions](https://stripe.com/docs/billing/subscriptions/discounts)
              attr_reader :discount

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end

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
            # The aggregated discounts.
            attr_reader :discounts
            # The aggregated tax amounts by rate.
            attr_reader :taxes

            def self.inner_class_types
              @inner_class_types = { discounts: Discount, taxes: Tax }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # This is the sum of all the discounts.
          attr_reader :amount_discount
          # This is the sum of all the shipping amounts.
          attr_reader :amount_shipping
          # This is the sum of all the tax amounts.
          attr_reader :amount_tax
          # Attribute for field breakdown
          attr_reader :breakdown

          def self.inner_class_types
            @inner_class_types = { breakdown: Breakdown }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Total before any discounts or taxes are applied.
        attr_reader :amount_subtotal
        # Total after discounts and taxes are applied.
        attr_reader :amount_total
        # The line items that will appear on the next invoice after this quote is accepted. This does not include pending invoice items that exist on the customer but may still be included in the next invoice.
        attr_reader :line_items
        # Attribute for field total_details
        attr_reader :total_details

        def self.inner_class_types
          @inner_class_types = { total_details: TotalDetails }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The definitive totals and line items the customer will be charged on a recurring basis. Takes into account the line items with recurring prices and discounts with `duration=forever` coupons only. Defaults to `null` if no inputted line items with recurring prices.
      attr_reader :recurring
      # Attribute for field upfront
      attr_reader :upfront

      def self.inner_class_types
        @inner_class_types = { recurring: Recurring, upfront: Upfront }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class FromQuote < ::Stripe::StripeObject
      # Whether this quote is a revision of a different quote.
      attr_reader :is_revision
      # The quote that was cloned.
      attr_reader :quote

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class InvoiceSettings < ::Stripe::StripeObject
      class Issuer < ::Stripe::StripeObject
        # The connected account being referenced when `type` is `account`.
        attr_reader :account
        # Type of the account referenced.
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Number of days within which a customer must pay invoices generated by this quote. This value will be `null` for quotes where `collection_method=charge_automatically`.
      attr_reader :days_until_due
      # Attribute for field issuer
      attr_reader :issuer

      def self.inner_class_types
        @inner_class_types = { issuer: Issuer }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class StatusTransitions < ::Stripe::StripeObject
      # The time that the quote was accepted. Measured in seconds since Unix epoch.
      attr_reader :accepted_at
      # The time that the quote was canceled. Measured in seconds since Unix epoch.
      attr_reader :canceled_at
      # The time that the quote was finalized. Measured in seconds since Unix epoch.
      attr_reader :finalized_at

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class SubscriptionData < ::Stripe::StripeObject
      class BillingMode < ::Stripe::StripeObject
        class Flexible < ::Stripe::StripeObject
          # Controls how invoices and invoice items display proration amounts and discount amounts.
          attr_reader :proration_discounts

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field flexible
        attr_reader :flexible
        # Controls how prorations and invoices for subscriptions are calculated and orchestrated.
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = { flexible: Flexible }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The billing mode of the quote.
      attr_reader :billing_mode
      # The subscription's description, meant to be displayable to the customer. Use this field to optionally store an explanation of the subscription for rendering in Stripe surfaces and certain local payment methods UIs.
      attr_reader :description
      # When creating a new subscription, the date of which the subscription schedule will start after the quote is accepted. This date is ignored if it is in the past when the quote is accepted. Measured in seconds since the Unix epoch.
      attr_reader :effective_date
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that will set metadata on the subscription or subscription schedule when the quote is accepted. If a recurring price is included in `line_items`, this field will be passed to the resulting subscription's `metadata` field. If `subscription_data.effective_date` is used, this field will be passed to the resulting subscription schedule's `phases.metadata` field. Unlike object-level metadata, this field is declarative. Updates will clear prior values.
      attr_reader :metadata
      # Integer representing the number of trial period days before the customer is charged for the first time.
      attr_reader :trial_period_days

      def self.inner_class_types
        @inner_class_types = { billing_mode: BillingMode }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class TotalDetails < ::Stripe::StripeObject
      class Breakdown < ::Stripe::StripeObject
        class Discount < ::Stripe::StripeObject
          # The amount discounted.
          attr_reader :amount
          # A discount represents the actual application of a [coupon](https://stripe.com/docs/api#coupons) or [promotion code](https://stripe.com/docs/api#promotion_codes).
          # It contains information about when the discount began, when it will end, and what it is applied to.
          #
          # Related guide: [Applying discounts to subscriptions](https://stripe.com/docs/billing/subscriptions/discounts)
          attr_reader :discount

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

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
        # The aggregated discounts.
        attr_reader :discounts
        # The aggregated tax amounts by rate.
        attr_reader :taxes

        def self.inner_class_types
          @inner_class_types = { discounts: Discount, taxes: Tax }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # This is the sum of all the discounts.
      attr_reader :amount_discount
      # This is the sum of all the shipping amounts.
      attr_reader :amount_shipping
      # This is the sum of all the tax amounts.
      attr_reader :amount_tax
      # Attribute for field breakdown
      attr_reader :breakdown

      def self.inner_class_types
        @inner_class_types = { breakdown: Breakdown }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class TransferData < ::Stripe::StripeObject
      # The amount in cents (or local equivalent) that will be transferred to the destination account when the invoice is paid. By default, the entire amount is transferred to the destination.
      attr_reader :amount
      # A non-negative decimal between 0 and 100, with at most two decimal places. This represents the percentage of the subscription invoice total that will be transferred to the destination account. By default, the entire amount will be transferred to the destination.
      attr_reader :amount_percent
      # The account where funds from the payment will be transferred to upon payment success.
      attr_reader :destination

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Total before any discounts or taxes are applied.
    attr_reader :amount_subtotal
    # Total after discounts and taxes are applied.
    attr_reader :amount_total
    # ID of the Connect Application that created the quote.
    attr_reader :application
    # The amount of the application fee (if any) that will be requested to be applied to the payment and transferred to the application owner's Stripe account. Only applicable if there are no line items with recurring prices on the quote.
    attr_reader :application_fee_amount
    # A non-negative decimal between 0 and 100, with at most two decimal places. This represents the percentage of the subscription invoice total that will be transferred to the application owner's Stripe account. Only applicable if there are line items with recurring prices on the quote.
    attr_reader :application_fee_percent
    # Attribute for field automatic_tax
    attr_reader :automatic_tax
    # Either `charge_automatically`, or `send_invoice`. When charging automatically, Stripe will attempt to pay invoices at the end of the subscription cycle or on finalization using the default payment method attached to the subscription or customer. When sending an invoice, Stripe will email your customer an invoice with payment instructions and mark the subscription as `active`. Defaults to `charge_automatically`.
    attr_reader :collection_method
    # Attribute for field computed
    attr_reader :computed
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # The customer which this quote belongs to. A customer is required before finalizing the quote. Once specified, it cannot be changed.
    attr_reader :customer
    # The tax rates applied to this quote.
    attr_reader :default_tax_rates
    # A description that will be displayed on the quote PDF.
    attr_reader :description
    # The discounts applied to this quote.
    attr_reader :discounts
    # The date on which the quote will be canceled if in `open` or `draft` status. Measured in seconds since the Unix epoch.
    attr_reader :expires_at
    # A footer that will be displayed on the quote PDF.
    attr_reader :footer
    # Details of the quote that was cloned. See the [cloning documentation](https://stripe.com/docs/quotes/clone) for more details.
    attr_reader :from_quote
    # A header that will be displayed on the quote PDF.
    attr_reader :header
    # Unique identifier for the object.
    attr_reader :id
    # The invoice that was created from this quote.
    attr_reader :invoice
    # Attribute for field invoice_settings
    attr_reader :invoice_settings
    # A list of items the customer is being quoted for.
    attr_reader :line_items
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # A unique number that identifies this particular quote. This number is assigned once the quote is [finalized](https://stripe.com/docs/quotes/overview#finalize).
    attr_reader :number
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The account on behalf of which to charge. See the [Connect documentation](https://support.stripe.com/questions/sending-invoices-on-behalf-of-connected-accounts) for details.
    attr_reader :on_behalf_of
    # The status of the quote.
    attr_reader :status
    # Attribute for field status_transitions
    attr_reader :status_transitions
    # The subscription that was created or updated from this quote.
    attr_reader :subscription
    # Attribute for field subscription_data
    attr_reader :subscription_data
    # The subscription schedule that was created or updated from this quote.
    attr_reader :subscription_schedule
    # ID of the test clock this quote belongs to.
    attr_reader :test_clock
    # Attribute for field total_details
    attr_reader :total_details
    # The account (if any) the payments will be attributed to for tax reporting, and where funds from each payment will be transferred to for each of the invoices.
    attr_reader :transfer_data

    # Accepts the specified quote.
    def accept(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/quotes/%<quote>s/accept", { quote: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Accepts the specified quote.
    def self.accept(quote, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/quotes/%<quote>s/accept", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts
      )
    end

    # Cancels the quote.
    def cancel(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/quotes/%<quote>s/cancel", { quote: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Cancels the quote.
    def self.cancel(quote, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/quotes/%<quote>s/cancel", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts
      )
    end

    # A quote models prices and services for a customer. Default options for header, description, footer, and expires_at can be set in the dashboard via the [quote template](https://dashboard.stripe.com/settings/billing/quote).
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/quotes", params: params, opts: opts)
    end

    # Finalizes the quote.
    def finalize_quote(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/quotes/%<quote>s/finalize", { quote: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Finalizes the quote.
    def self.finalize_quote(quote, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/quotes/%<quote>s/finalize", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts
      )
    end

    # Returns a list of your quotes.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/quotes", params: params, opts: opts)
    end

    # When retrieving a quote, there is an includable [computed.upfront.line_items](https://stripe.com/docs/api/quotes/object#quote_object-computed-upfront-line_items) property containing the first handful of those items. There is also a URL where you can retrieve the full (paginated) list of upfront line items.
    def list_computed_upfront_line_items(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: format("/v1/quotes/%<quote>s/computed_upfront_line_items", { quote: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # When retrieving a quote, there is an includable [computed.upfront.line_items](https://stripe.com/docs/api/quotes/object#quote_object-computed-upfront-line_items) property containing the first handful of those items. There is also a URL where you can retrieve the full (paginated) list of upfront line items.
    def self.list_computed_upfront_line_items(quote, params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: format("/v1/quotes/%<quote>s/computed_upfront_line_items", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts
      )
    end

    # When retrieving a quote, there is an includable line_items property containing the first handful of those items. There is also a URL where you can retrieve the full (paginated) list of line items.
    def list_line_items(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: format("/v1/quotes/%<quote>s/line_items", { quote: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # When retrieving a quote, there is an includable line_items property containing the first handful of those items. There is also a URL where you can retrieve the full (paginated) list of line items.
    def self.list_line_items(quote, params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: format("/v1/quotes/%<quote>s/line_items", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts
      )
    end

    # Download the PDF for a finalized quote. Explanation for special handling can be found [here](https://docs.stripe.com/quotes/overview#quote_pdf)
    def pdf(params = {}, opts = {}, &read_body_chunk_block)
      opts = { api_base: APIRequestor.active_requestor.config.uploads_base }.merge(opts)
      request_stream(
        method: :get,
        path: format("/v1/quotes/%<quote>s/pdf", { quote: CGI.escape(self["id"]) }),
        params: params,
        opts: opts,
        base_address: :files,
        &read_body_chunk_block
      )
    end

    # Download the PDF for a finalized quote. Explanation for special handling can be found [here](https://docs.stripe.com/quotes/overview#quote_pdf)
    def self.pdf(quote, params = {}, opts = {}, &read_body_chunk_block)
      opts = { api_base: APIRequestor.active_requestor.config.uploads_base }.merge(opts)
      execute_resource_request_stream(
        :get,
        format("/v1/quotes/%<quote>s/pdf", { quote: CGI.escape(quote) }),
        :files,
        params,
        opts,
        &read_body_chunk_block
      )
    end

    # A quote models prices and services for a customer.
    def self.update(quote, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/quotes/%<quote>s", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {
        automatic_tax: AutomaticTax,
        computed: Computed,
        from_quote: FromQuote,
        invoice_settings: InvoiceSettings,
        status_transitions: StatusTransitions,
        subscription_data: SubscriptionData,
        total_details: TotalDetails,
        transfer_data: TransferData,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
