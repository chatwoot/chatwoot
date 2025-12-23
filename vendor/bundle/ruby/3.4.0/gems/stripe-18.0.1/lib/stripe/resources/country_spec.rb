# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Stripe needs to collect certain pieces of information about each account
  # created. These requirements can differ depending on the account's country. The
  # Country Specs API makes these rules available to your integration.
  #
  # You can also view the information from this API call as [an online
  # guide](https://docs.stripe.com/docs/connect/required-verification-information).
  class CountrySpec < APIResource
    extend Stripe::APIOperations::List

    OBJECT_NAME = "country_spec"
    def self.object_name
      "country_spec"
    end

    class VerificationFields < ::Stripe::StripeObject
      class Company < ::Stripe::StripeObject
        # Additional fields which are only required for some users.
        attr_reader :additional
        # Fields which every account must eventually provide.
        attr_reader :minimum

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Individual < ::Stripe::StripeObject
        # Additional fields which are only required for some users.
        attr_reader :additional
        # Fields which every account must eventually provide.
        attr_reader :minimum

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field company
      attr_reader :company
      # Attribute for field individual
      attr_reader :individual

      def self.inner_class_types
        @inner_class_types = { company: Company, individual: Individual }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # The default currency for this country. This applies to both payment methods and bank accounts.
    attr_reader :default_currency
    # Unique identifier for the object. Represented as the ISO country code for this country.
    attr_reader :id
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Currencies that can be accepted in the specific country (for transfers).
    attr_reader :supported_bank_account_currencies
    # Currencies that can be accepted in the specified country (for payments).
    attr_reader :supported_payment_currencies
    # Payment methods available in the specified country. You may need to enable some payment methods (e.g., [ACH](https://stripe.com/docs/ach)) on your account before they appear in this list. The `stripe` payment method refers to [charging through your platform](https://stripe.com/docs/connect/destination-charges).
    attr_reader :supported_payment_methods
    # Countries that can accept transfers from the specified country.
    attr_reader :supported_transfer_countries
    # Attribute for field verification_fields
    attr_reader :verification_fields

    # Lists all Country Spec objects available in the API.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/country_specs", params: params, opts: opts)
    end

    def self.inner_class_types
      @inner_class_types = { verification_fields: VerificationFields }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
