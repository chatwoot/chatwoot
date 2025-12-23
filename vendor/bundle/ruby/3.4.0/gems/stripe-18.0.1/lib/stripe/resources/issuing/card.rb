# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    # You can [create physical or virtual cards](https://stripe.com/docs/issuing) that are issued to cardholders.
    class Card < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "issuing.card"
      def self.object_name
        "issuing.card"
      end

      class LatestFraudWarning < ::Stripe::StripeObject
        # Timestamp of the most recent fraud warning.
        attr_reader :started_at
        # The type of fraud warning that most recently took place on this card. This field updates with every new fraud warning, so the value changes over time. If populated, cancel and reissue the card.
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = {}
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

        class AddressValidation < ::Stripe::StripeObject
          class NormalizedAddress < ::Stripe::StripeObject
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
          # The address validation capabilities to use.
          attr_reader :mode
          # The normalized shipping address.
          attr_reader :normalized_address
          # The validation result for the shipping address.
          attr_reader :result

          def self.inner_class_types
            @inner_class_types = { normalized_address: NormalizedAddress }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Customs < ::Stripe::StripeObject
          # A registration number used for customs in Europe. See [https://www.gov.uk/eori](https://www.gov.uk/eori) for the UK and [https://ec.europa.eu/taxation_customs/business/customs-procedures-import-and-export/customs-procedures/economic-operators-registration-and-identification-number-eori_en](https://ec.europa.eu/taxation_customs/business/customs-procedures-import-and-export/customs-procedures/economic-operators-registration-and-identification-number-eori_en) for the EU.
          attr_reader :eori_number

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field address
        attr_reader :address
        # Address validation details for the shipment.
        attr_reader :address_validation
        # The delivery company that shipped a card.
        attr_reader :carrier
        # Additional information that may be required for clearing customs.
        attr_reader :customs
        # A unix timestamp representing a best estimate of when the card will be delivered.
        attr_reader :eta
        # Recipient name.
        attr_reader :name
        # The phone number of the receiver of the shipment. Our courier partners will use this number to contact you in the event of card delivery issues. For individual shipments to the EU/UK, if this field is empty, we will provide them with the phone number provided when the cardholder was initially created.
        attr_reader :phone_number
        # Whether a signature is required for card delivery. This feature is only supported for US users. Standard shipping service does not support signature on delivery. The default value for standard shipping service is false and for express and priority services is true.
        attr_reader :require_signature
        # Shipment service, such as `standard` or `express`.
        attr_reader :service
        # The delivery status of the card.
        attr_reader :status
        # A tracking number for a card shipment.
        attr_reader :tracking_number
        # A link to the shipping carrier's site where you can view detailed information about a card shipment.
        attr_reader :tracking_url
        # Packaging options.
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = {
            address: Address,
            address_validation: AddressValidation,
            customs: Customs,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class SpendingControls < ::Stripe::StripeObject
        class SpendingLimit < ::Stripe::StripeObject
          # Maximum amount allowed to spend per interval. This amount is in the card's currency and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
          attr_reader :amount
          # Array of strings containing [categories](https://stripe.com/docs/api#issuing_authorization_object-merchant_data-category) this limit applies to. Omitting this field will apply the limit to all categories.
          attr_reader :categories
          # Interval (or event) to which the amount applies.
          attr_reader :interval

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Array of strings containing [categories](https://stripe.com/docs/api#issuing_authorization_object-merchant_data-category) of authorizations to allow. All other categories will be blocked. Cannot be set with `blocked_categories`.
        attr_reader :allowed_categories
        # Array of strings containing representing countries from which authorizations will be allowed. Authorizations from merchants in all other countries will be declined. Country codes should be ISO 3166 alpha-2 country codes (e.g. `US`). Cannot be set with `blocked_merchant_countries`. Provide an empty value to unset this control.
        attr_reader :allowed_merchant_countries
        # Array of strings containing [categories](https://stripe.com/docs/api#issuing_authorization_object-merchant_data-category) of authorizations to decline. All other categories will be allowed. Cannot be set with `allowed_categories`.
        attr_reader :blocked_categories
        # Array of strings containing representing countries from which authorizations will be declined. Country codes should be ISO 3166 alpha-2 country codes (e.g. `US`). Cannot be set with `allowed_merchant_countries`. Provide an empty value to unset this control.
        attr_reader :blocked_merchant_countries
        # Limit spending with amount-based rules that apply across any cards this card replaced (i.e., its `replacement_for` card and _that_ card's `replacement_for` card, up the chain).
        attr_reader :spending_limits
        # Currency of the amounts within `spending_limits`. Always the same as the currency of the card.
        attr_reader :spending_limits_currency

        def self.inner_class_types
          @inner_class_types = { spending_limits: SpendingLimit }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Wallets < ::Stripe::StripeObject
        class ApplePay < ::Stripe::StripeObject
          # Apple Pay Eligibility
          attr_reader :eligible
          # Reason the card is ineligible for Apple Pay
          attr_reader :ineligible_reason

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class GooglePay < ::Stripe::StripeObject
          # Google Pay Eligibility
          attr_reader :eligible
          # Reason the card is ineligible for Google Pay
          attr_reader :ineligible_reason

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field apple_pay
        attr_reader :apple_pay
        # Attribute for field google_pay
        attr_reader :google_pay
        # Unique identifier for a card used with digital wallets
        attr_reader :primary_account_identifier

        def self.inner_class_types
          @inner_class_types = { apple_pay: ApplePay, google_pay: GooglePay }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The brand of the card.
      attr_reader :brand
      # The reason why the card was canceled.
      attr_reader :cancellation_reason
      # An Issuing `Cardholder` object represents an individual or business entity who is [issued](https://stripe.com/docs/issuing) cards.
      #
      # Related guide: [How to create a cardholder](https://stripe.com/docs/issuing/cards/virtual/issue-cards#create-cardholder)
      attr_reader :cardholder
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Supported currencies are `usd` in the US, `eur` in the EU, and `gbp` in the UK.
      attr_reader :currency
      # The card's CVC. For security reasons, this is only available for virtual cards, and will be omitted unless you explicitly request it with [the `expand` parameter](https://stripe.com/docs/api/expanding_objects). Additionally, it's only available via the ["Retrieve a card" endpoint](https://stripe.com/docs/api/issuing/cards/retrieve), not via "List all cards" or any other endpoint.
      attr_reader :cvc
      # The expiration month of the card.
      attr_reader :exp_month
      # The expiration year of the card.
      attr_reader :exp_year
      # The financial account this card is attached to.
      attr_reader :financial_account
      # Unique identifier for the object.
      attr_reader :id
      # The last 4 digits of the card number.
      attr_reader :last4
      # Stripe’s assessment of whether this card’s details have been compromised. If this property isn't null, cancel and reissue the card to prevent fraudulent activity risk.
      attr_reader :latest_fraud_warning
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # The full unredacted card number. For security reasons, this is only available for virtual cards, and will be omitted unless you explicitly request it with [the `expand` parameter](https://stripe.com/docs/api/expanding_objects). Additionally, it's only available via the ["Retrieve a card" endpoint](https://stripe.com/docs/api/issuing/cards/retrieve), not via "List all cards" or any other endpoint.
      attr_reader :number
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The personalization design object belonging to this card.
      attr_reader :personalization_design
      # The latest card that replaces this card, if any.
      attr_reader :replaced_by
      # The card this card replaces, if any.
      attr_reader :replacement_for
      # The reason why the previous card needed to be replaced.
      attr_reader :replacement_reason
      # Text separate from cardholder name, printed on the card.
      attr_reader :second_line
      # Where and how the card will be shipped.
      attr_reader :shipping
      # Attribute for field spending_controls
      attr_reader :spending_controls
      # Whether authorizations can be approved on this card. May be blocked from activating cards depending on past-due Cardholder requirements. Defaults to `inactive`.
      attr_reader :status
      # The type of the card.
      attr_reader :type
      # Information relating to digital wallets (like Apple Pay and Google Pay).
      attr_reader :wallets

      # Creates an Issuing Card object.
      def self.create(params = {}, opts = {})
        request_stripe_object(method: :post, path: "/v1/issuing/cards", params: params, opts: opts)
      end

      # Returns a list of Issuing Card objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def self.list(params = {}, opts = {})
        request_stripe_object(method: :get, path: "/v1/issuing/cards", params: params, opts: opts)
      end

      # Updates the specified Issuing Card object by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
      def self.update(card, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/issuing/cards/%<card>s", { card: CGI.escape(card) }),
          params: params,
          opts: opts
        )
      end

      def test_helpers
        TestHelpers.new(self)
      end

      class TestHelpers < APIResourceTestHelpers
        RESOURCE_CLASS = Card
        def self.resource_class
          "Card"
        end

        # Updates the shipping status of the specified Issuing Card object to delivered.
        def self.deliver_card(card, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/deliver", { card: CGI.escape(card) }),
            params: params,
            opts: opts
          )
        end

        # Updates the shipping status of the specified Issuing Card object to delivered.
        def deliver_card(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/deliver", { card: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Updates the shipping status of the specified Issuing Card object to failure.
        def self.fail_card(card, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/fail", { card: CGI.escape(card) }),
            params: params,
            opts: opts
          )
        end

        # Updates the shipping status of the specified Issuing Card object to failure.
        def fail_card(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/fail", { card: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Updates the shipping status of the specified Issuing Card object to returned.
        def self.return_card(card, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/return", { card: CGI.escape(card) }),
            params: params,
            opts: opts
          )
        end

        # Updates the shipping status of the specified Issuing Card object to returned.
        def return_card(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/return", { card: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Updates the shipping status of the specified Issuing Card object to shipped.
        def self.ship_card(card, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/ship", { card: CGI.escape(card) }),
            params: params,
            opts: opts
          )
        end

        # Updates the shipping status of the specified Issuing Card object to shipped.
        def ship_card(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/ship", { card: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Updates the shipping status of the specified Issuing Card object to submitted. This method requires Stripe Version ‘2024-09-30.acacia' or later.
        def self.submit_card(card, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/submit", { card: CGI.escape(card) }),
            params: params,
            opts: opts
          )
        end

        # Updates the shipping status of the specified Issuing Card object to submitted. This method requires Stripe Version ‘2024-09-30.acacia' or later.
        def submit_card(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/submit", { card: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end
      end

      def self.inner_class_types
        @inner_class_types = {
          latest_fraud_warning: LatestFraudWarning,
          shipping: Shipping,
          spending_controls: SpendingControls,
          wallets: Wallets,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
