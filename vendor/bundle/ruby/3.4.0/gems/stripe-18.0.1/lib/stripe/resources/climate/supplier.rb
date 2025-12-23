# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Climate
    # A supplier of carbon removal.
    class Supplier < APIResource
      extend Stripe::APIOperations::List

      OBJECT_NAME = "climate.supplier"
      def self.object_name
        "climate.supplier"
      end

      class Location < ::Stripe::StripeObject
        # The city where the supplier is located.
        attr_reader :city
        # Two-letter ISO code representing the country where the supplier is located.
        attr_reader :country
        # The geographic latitude where the supplier is located.
        attr_reader :latitude
        # The geographic longitude where the supplier is located.
        attr_reader :longitude
        # The state/county/province/region where the supplier is located.
        attr_reader :region

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Unique identifier for the object.
      attr_reader :id
      # Link to a webpage to learn more about the supplier.
      attr_reader :info_url
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # The locations in which this supplier operates.
      attr_reader :locations
      # Name of this carbon removal supplier.
      attr_reader :name
      # String representing the object’s type. Objects of the same type share the same value.
      attr_reader :object
      # The scientific pathway used for carbon removal.
      attr_reader :removal_pathway

      # Lists all available Climate supplier objects.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/climate/suppliers",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = { locations: Location }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
