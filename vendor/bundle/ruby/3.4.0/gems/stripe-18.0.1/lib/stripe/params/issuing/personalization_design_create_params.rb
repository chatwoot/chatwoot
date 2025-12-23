# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class PersonalizationDesignCreateParams < ::Stripe::RequestParams
      class CarrierText < ::Stripe::RequestParams
        # The footer body text of the carrier letter.
        attr_accessor :footer_body
        # The footer title text of the carrier letter.
        attr_accessor :footer_title
        # The header body text of the carrier letter.
        attr_accessor :header_body
        # The header title text of the carrier letter.
        attr_accessor :header_title

        def initialize(footer_body: nil, footer_title: nil, header_body: nil, header_title: nil)
          @footer_body = footer_body
          @footer_title = footer_title
          @header_body = header_body
          @header_title = header_title
        end
      end

      class Preferences < ::Stripe::RequestParams
        # Whether we use this personalization design to create cards when one isn't specified. A connected account uses the Connect platform's default design if no personalization design is set as the default design.
        attr_accessor :is_default

        def initialize(is_default: nil)
          @is_default = is_default
        end
      end
      # The file for the card logo, for use with physical bundles that support card logos. Must have a `purpose` value of `issuing_logo`.
      attr_accessor :card_logo
      # Hash containing carrier text, for use with physical bundles that support carrier text.
      attr_accessor :carrier_text
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # A lookup key used to retrieve personalization designs dynamically from a static string. This may be up to 200 characters.
      attr_accessor :lookup_key
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # Friendly display name.
      attr_accessor :name
      # The physical bundle object belonging to this personalization design.
      attr_accessor :physical_bundle
      # Information on whether this personalization design is used to create cards when one is not specified.
      attr_accessor :preferences
      # If set to true, will atomically remove the lookup key from the existing personalization design, and assign it to this personalization design.
      attr_accessor :transfer_lookup_key

      def initialize(
        card_logo: nil,
        carrier_text: nil,
        expand: nil,
        lookup_key: nil,
        metadata: nil,
        name: nil,
        physical_bundle: nil,
        preferences: nil,
        transfer_lookup_key: nil
      )
        @card_logo = card_logo
        @carrier_text = carrier_text
        @expand = expand
        @lookup_key = lookup_key
        @metadata = metadata
        @name = name
        @physical_bundle = physical_bundle
        @preferences = preferences
        @transfer_lookup_key = transfer_lookup_key
      end
    end
  end
end
