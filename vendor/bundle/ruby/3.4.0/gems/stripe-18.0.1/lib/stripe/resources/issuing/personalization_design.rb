# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    # A Personalization Design is a logical grouping of a Physical Bundle, card logo, and carrier text that represents a product line.
    class PersonalizationDesign < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "issuing.personalization_design"
      def self.object_name
        "issuing.personalization_design"
      end

      class CarrierText < ::Stripe::StripeObject
        # The footer body text of the carrier letter.
        attr_reader :footer_body
        # The footer title text of the carrier letter.
        attr_reader :footer_title
        # The header body text of the carrier letter.
        attr_reader :header_body
        # The header title text of the carrier letter.
        attr_reader :header_title

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Preferences < ::Stripe::StripeObject
        # Whether we use this personalization design to create cards when one isn't specified. A connected account uses the Connect platform's default design if no personalization design is set as the default design.
        attr_reader :is_default
        # Whether this personalization design is used to create cards when one is not specified and a default for this connected account does not exist.
        attr_reader :is_platform_default

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class RejectionReasons < ::Stripe::StripeObject
        # The reason(s) the card logo was rejected.
        attr_reader :card_logo
        # The reason(s) the carrier text was rejected.
        attr_reader :carrier_text

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The file for the card logo to use with physical bundles that support card logos. Must have a `purpose` value of `issuing_logo`.
      attr_reader :card_logo
      # Hash containing carrier text, for use with physical bundles that support carrier text.
      attr_reader :carrier_text
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # A lookup key used to retrieve personalization designs dynamically from a static string. This may be up to 200 characters.
      attr_reader :lookup_key
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # Friendly display name.
      attr_reader :name
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The physical bundle object belonging to this personalization design.
      attr_reader :physical_bundle
      # Attribute for field preferences
      attr_reader :preferences
      # Attribute for field rejection_reasons
      attr_reader :rejection_reasons
      # Whether this personalization design can be used to create cards.
      attr_reader :status

      # Creates a personalization design object.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/issuing/personalization_designs",
          params: params,
          opts: opts
        )
      end

      # Returns a list of personalization design objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/issuing/personalization_designs",
          params: params,
          opts: opts
        )
      end

      # Updates a card personalization object.
      def self.update(personalization_design, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/issuing/personalization_designs/%<personalization_design>s", { personalization_design: CGI.escape(personalization_design) }),
          params: params,
          opts: opts
        )
      end

      def test_helpers
        TestHelpers.new(self)
      end

      class TestHelpers < APIResourceTestHelpers
        RESOURCE_CLASS = PersonalizationDesign
        def self.resource_class
          "PersonalizationDesign"
        end

        # Updates the status of the specified testmode personalization design object to active.
        def self.activate(personalization_design, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/personalization_designs/%<personalization_design>s/activate", { personalization_design: CGI.escape(personalization_design) }),
            params: params,
            opts: opts
          )
        end

        # Updates the status of the specified testmode personalization design object to active.
        def activate(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/personalization_designs/%<personalization_design>s/activate", { personalization_design: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Updates the status of the specified testmode personalization design object to inactive.
        def self.deactivate(personalization_design, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/personalization_designs/%<personalization_design>s/deactivate", { personalization_design: CGI.escape(personalization_design) }),
            params: params,
            opts: opts
          )
        end

        # Updates the status of the specified testmode personalization design object to inactive.
        def deactivate(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/personalization_designs/%<personalization_design>s/deactivate", { personalization_design: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Updates the status of the specified testmode personalization design object to rejected.
        def self.reject(personalization_design, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/personalization_designs/%<personalization_design>s/reject", { personalization_design: CGI.escape(personalization_design) }),
            params: params,
            opts: opts
          )
        end

        # Updates the status of the specified testmode personalization design object to rejected.
        def reject(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/issuing/personalization_designs/%<personalization_design>s/reject", { personalization_design: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end
      end

      def self.inner_class_types
        @inner_class_types = {
          carrier_text: CarrierText,
          preferences: Preferences,
          rejection_reasons: RejectionReasons,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
