# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class CardUpdateParams < ::Stripe::RequestParams
      class Pin < ::Stripe::RequestParams
        # The card's desired new PIN, encrypted under Stripe's public key.
        attr_accessor :encrypted_number

        def initialize(encrypted_number: nil)
          @encrypted_number = encrypted_number
        end
      end

      class Shipping < ::Stripe::RequestParams
        class Address < ::Stripe::RequestParams
          # City, district, suburb, town, or village.
          attr_accessor :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_accessor :country
          # Address line 1, such as the street, PO Box, or company name.
          attr_accessor :line1
          # Address line 2, such as the apartment, suite, unit, or building.
          attr_accessor :line2
          # ZIP or postal code.
          attr_accessor :postal_code
          # State, county, province, or region.
          attr_accessor :state

          def initialize(
            city: nil,
            country: nil,
            line1: nil,
            line2: nil,
            postal_code: nil,
            state: nil
          )
            @city = city
            @country = country
            @line1 = line1
            @line2 = line2
            @postal_code = postal_code
            @state = state
          end
        end

        class AddressValidation < ::Stripe::RequestParams
          # The address validation capabilities to use.
          attr_accessor :mode

          def initialize(mode: nil)
            @mode = mode
          end
        end

        class Customs < ::Stripe::RequestParams
          # The Economic Operators Registration and Identification (EORI) number to use for Customs. Required for bulk shipments to Europe.
          attr_accessor :eori_number

          def initialize(eori_number: nil)
            @eori_number = eori_number
          end
        end
        # The address that the card is shipped to.
        attr_accessor :address
        # Address validation settings.
        attr_accessor :address_validation
        # Customs information for the shipment.
        attr_accessor :customs
        # The name printed on the shipping label when shipping the card.
        attr_accessor :name
        # Phone number of the recipient of the shipment.
        attr_accessor :phone_number
        # Whether a signature is required for card delivery.
        attr_accessor :require_signature
        # Shipment service.
        attr_accessor :service
        # Packaging options.
        attr_accessor :type

        def initialize(
          address: nil,
          address_validation: nil,
          customs: nil,
          name: nil,
          phone_number: nil,
          require_signature: nil,
          service: nil,
          type: nil
        )
          @address = address
          @address_validation = address_validation
          @customs = customs
          @name = name
          @phone_number = phone_number
          @require_signature = require_signature
          @service = service
          @type = type
        end
      end

      class SpendingControls < ::Stripe::RequestParams
        class SpendingLimit < ::Stripe::RequestParams
          # Maximum amount allowed to spend per interval.
          attr_accessor :amount
          # Array of strings containing [categories](https://stripe.com/docs/api#issuing_authorization_object-merchant_data-category) this limit applies to. Omitting this field will apply the limit to all categories.
          attr_accessor :categories
          # Interval (or event) to which the amount applies.
          attr_accessor :interval

          def initialize(amount: nil, categories: nil, interval: nil)
            @amount = amount
            @categories = categories
            @interval = interval
          end
        end
        # Array of strings containing [categories](https://stripe.com/docs/api#issuing_authorization_object-merchant_data-category) of authorizations to allow. All other categories will be blocked. Cannot be set with `blocked_categories`.
        attr_accessor :allowed_categories
        # Array of strings containing representing countries from which authorizations will be allowed. Authorizations from merchants in all other countries will be declined. Country codes should be ISO 3166 alpha-2 country codes (e.g. `US`). Cannot be set with `blocked_merchant_countries`. Provide an empty value to unset this control.
        attr_accessor :allowed_merchant_countries
        # Array of strings containing [categories](https://stripe.com/docs/api#issuing_authorization_object-merchant_data-category) of authorizations to decline. All other categories will be allowed. Cannot be set with `allowed_categories`.
        attr_accessor :blocked_categories
        # Array of strings containing representing countries from which authorizations will be declined. Country codes should be ISO 3166 alpha-2 country codes (e.g. `US`). Cannot be set with `allowed_merchant_countries`. Provide an empty value to unset this control.
        attr_accessor :blocked_merchant_countries
        # Limit spending with amount-based rules that apply across any cards this card replaced (i.e., its `replacement_for` card and _that_ card's `replacement_for` card, up the chain).
        attr_accessor :spending_limits

        def initialize(
          allowed_categories: nil,
          allowed_merchant_countries: nil,
          blocked_categories: nil,
          blocked_merchant_countries: nil,
          spending_limits: nil
        )
          @allowed_categories = allowed_categories
          @allowed_merchant_countries = allowed_merchant_countries
          @blocked_categories = blocked_categories
          @blocked_merchant_countries = blocked_merchant_countries
          @spending_limits = spending_limits
        end
      end
      # Reason why the `status` of this card is `canceled`.
      attr_accessor :cancellation_reason
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # Attribute for param field personalization_design
      attr_accessor :personalization_design
      # The desired new PIN for this card.
      attr_accessor :pin
      # Updated shipping information for the card.
      attr_accessor :shipping
      # Rules that control spending for this card. Refer to our [documentation](https://stripe.com/docs/issuing/controls/spending-controls) for more details.
      attr_accessor :spending_controls
      # Dictates whether authorizations can be approved on this card. May be blocked from activating cards depending on past-due Cardholder requirements. Defaults to `inactive`. If this card is being canceled because it was lost or stolen, this information should be provided as `cancellation_reason`.
      attr_accessor :status

      def initialize(
        cancellation_reason: nil,
        expand: nil,
        metadata: nil,
        personalization_design: nil,
        pin: nil,
        shipping: nil,
        spending_controls: nil,
        status: nil
      )
        @cancellation_reason = cancellation_reason
        @expand = expand
        @metadata = metadata
        @personalization_design = personalization_design
        @pin = pin
        @shipping = shipping
        @spending_controls = spending_controls
        @status = status
      end
    end
  end
end
