# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    # An Issuing `Cardholder` object represents an individual or business entity who is [issued](https://stripe.com/docs/issuing) cards.
    #
    # Related guide: [How to create a cardholder](https://stripe.com/docs/issuing/cards/virtual/issue-cards#create-cardholder)
    class Cardholder < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "issuing.cardholder"
      def self.object_name
        "issuing.cardholder"
      end

      class Billing < ::Stripe::StripeObject
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

        def self.inner_class_types
          @inner_class_types = { address: Address }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Company < ::Stripe::StripeObject
        # Whether the company's business ID number was provided.
        attr_reader :tax_id_provided

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Individual < ::Stripe::StripeObject
        class CardIssuing < ::Stripe::StripeObject
          class UserTermsAcceptance < ::Stripe::StripeObject
            # The Unix timestamp marking when the cardholder accepted the Authorized User Terms.
            attr_reader :date
            # The IP address from which the cardholder accepted the Authorized User Terms.
            attr_reader :ip
            # The user agent of the browser from which the cardholder accepted the Authorized User Terms.
            attr_reader :user_agent

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Information about cardholder acceptance of Celtic [Authorized User Terms](https://stripe.com/docs/issuing/cards#accept-authorized-user-terms). Required for cards backed by a Celtic program.
          attr_reader :user_terms_acceptance

          def self.inner_class_types
            @inner_class_types = { user_terms_acceptance: UserTermsAcceptance }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Dob < ::Stripe::StripeObject
          # The day of birth, between 1 and 31.
          attr_reader :day
          # The month of birth, between 1 and 12.
          attr_reader :month
          # The four-digit year of birth.
          attr_reader :year

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Verification < ::Stripe::StripeObject
          class Document < ::Stripe::StripeObject
            # The back of a document returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`.
            attr_reader :back
            # The front of a document returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`.
            attr_reader :front

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # An identifying document, either a passport or local ID card.
          attr_reader :document

          def self.inner_class_types
            @inner_class_types = { document: Document }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Information related to the card_issuing program for this cardholder.
        attr_reader :card_issuing
        # The date of birth of this cardholder.
        attr_reader :dob
        # The first name of this cardholder. Required before activating Cards. This field cannot contain any numbers, special characters (except periods, commas, hyphens, spaces and apostrophes) or non-latin letters.
        attr_reader :first_name
        # The last name of this cardholder. Required before activating Cards. This field cannot contain any numbers, special characters (except periods, commas, hyphens, spaces and apostrophes) or non-latin letters.
        attr_reader :last_name
        # Government-issued ID document for this cardholder.
        attr_reader :verification

        def self.inner_class_types
          @inner_class_types = { card_issuing: CardIssuing, dob: Dob, verification: Verification }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Requirements < ::Stripe::StripeObject
        # If `disabled_reason` is present, all cards will decline authorizations with `cardholder_verification_required` reason.
        attr_reader :disabled_reason
        # Array of fields that need to be collected in order to verify and re-enable the cardholder.
        attr_reader :past_due

        def self.inner_class_types
          @inner_class_types = {}
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
        # Limit spending with amount-based rules that apply across this cardholder's cards.
        attr_reader :spending_limits
        # Currency of the amounts within `spending_limits`.
        attr_reader :spending_limits_currency

        def self.inner_class_types
          @inner_class_types = { spending_limits: SpendingLimit }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field billing
      attr_reader :billing
      # Additional information about a `company` cardholder.
      attr_reader :company
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # The cardholder's email address.
      attr_reader :email
      # Unique identifier for the object.
      attr_reader :id
      # Additional information about an `individual` cardholder.
      attr_reader :individual
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # The cardholder's name. This will be printed on cards issued to them.
      attr_reader :name
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The cardholder's phone number. This is required for all cardholders who will be creating EU cards. See the [3D Secure documentation](https://stripe.com/docs/issuing/3d-secure#when-is-3d-secure-applied) for more details.
      attr_reader :phone_number
      # The cardholder’s preferred locales (languages), ordered by preference. Locales can be `de`, `en`, `es`, `fr`, or `it`.
      #  This changes the language of the [3D Secure flow](https://stripe.com/docs/issuing/3d-secure) and one-time password messages sent to the cardholder.
      attr_reader :preferred_locales
      # Attribute for field requirements
      attr_reader :requirements
      # Rules that control spending across this cardholder's cards. Refer to our [documentation](https://stripe.com/docs/issuing/controls/spending-controls) for more details.
      attr_reader :spending_controls
      # Specifies whether to permit authorizations on this cardholder's cards.
      attr_reader :status
      # One of `individual` or `company`. See [Choose a cardholder type](https://stripe.com/docs/issuing/other/choose-cardholder) for more details.
      attr_reader :type

      # Creates a new Issuing Cardholder object that can be issued cards.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/issuing/cardholders",
          params: params,
          opts: opts
        )
      end

      # Returns a list of Issuing Cardholder objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/issuing/cardholders",
          params: params,
          opts: opts
        )
      end

      # Updates the specified Issuing Cardholder object by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
      def self.update(cardholder, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/issuing/cardholders/%<cardholder>s", { cardholder: CGI.escape(cardholder) }),
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = {
          billing: Billing,
          company: Company,
          individual: Individual,
          requirements: Requirements,
          spending_controls: SpendingControls,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
