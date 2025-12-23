# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    # A Location represents a grouping of readers.
    #
    # Related guide: [Fleet management](https://stripe.com/docs/terminal/fleet/locations)
    class Location < APIResource
      extend Stripe::APIOperations::Create
      include Stripe::APIOperations::Delete
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "terminal.location"
      def self.object_name
        "terminal.location"
      end

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

      class AddressKana < ::Stripe::StripeObject
        # City/Ward.
        attr_reader :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_reader :country
        # Block/Building number.
        attr_reader :line1
        # Building details.
        attr_reader :line2
        # ZIP or postal code.
        attr_reader :postal_code
        # Prefecture.
        attr_reader :state
        # Town/cho-me.
        attr_reader :town

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class AddressKanji < ::Stripe::StripeObject
        # City/Ward.
        attr_reader :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_reader :country
        # Block/Building number.
        attr_reader :line1
        # Building details.
        attr_reader :line2
        # ZIP or postal code.
        attr_reader :postal_code
        # Prefecture.
        attr_reader :state
        # Town/cho-me.
        attr_reader :town

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field address
      attr_reader :address
      # Attribute for field address_kana
      attr_reader :address_kana
      # Attribute for field address_kanji
      attr_reader :address_kanji
      # The ID of a configuration that will be used to customize all readers in this location.
      attr_reader :configuration_overrides
      # The display name of the location.
      attr_reader :display_name
      # The Kana variation of the display name of the location.
      attr_reader :display_name_kana
      # The Kanji variation of the display name of the location.
      attr_reader :display_name_kanji
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The phone number of the location.
      attr_reader :phone
      # Always true for a deleted object
      attr_reader :deleted

      # Creates a new Location object.
      # For further details, including which address fields are required in each country, see the [Manage locations](https://docs.stripe.com/docs/terminal/fleet/locations) guide.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/terminal/locations",
          params: params,
          opts: opts
        )
      end

      # Deletes a Location object.
      def self.delete(location, params = {}, opts = {})
        request_stripe_object(
          method: :delete,
          path: format("/v1/terminal/locations/%<location>s", { location: CGI.escape(location) }),
          params: params,
          opts: opts
        )
      end

      # Deletes a Location object.
      def delete(params = {}, opts = {})
        request_stripe_object(
          method: :delete,
          path: format("/v1/terminal/locations/%<location>s", { location: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Returns a list of Location objects.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/terminal/locations",
          params: params,
          opts: opts
        )
      end

      # Updates a Location object by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
      def self.update(location, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/terminal/locations/%<location>s", { location: CGI.escape(location) }),
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = {
          address: Address,
          address_kana: AddressKana,
          address_kanji: AddressKanji,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
