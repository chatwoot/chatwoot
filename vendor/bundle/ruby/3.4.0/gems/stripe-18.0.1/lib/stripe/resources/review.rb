# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Reviews can be used to supplement automated fraud detection with human expertise.
  #
  # Learn more about [Radar](https://docs.stripe.com/radar) and reviewing payments
  # [here](https://stripe.com/docs/radar/reviews).
  class Review < APIResource
    extend Stripe::APIOperations::List

    OBJECT_NAME = "review"
    def self.object_name
      "review"
    end

    class IpAddressLocation < ::Stripe::StripeObject
      # The city where the payment originated.
      attr_reader :city
      # Two-letter ISO code representing the country where the payment originated.
      attr_reader :country
      # The geographic latitude where the payment originated.
      attr_reader :latitude
      # The geographic longitude where the payment originated.
      attr_reader :longitude
      # The state/county/province/region where the payment originated.
      attr_reader :region

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Session < ::Stripe::StripeObject
      # The browser used in this browser session (e.g., `Chrome`).
      attr_reader :browser
      # Information about the device used for the browser session (e.g., `Samsung SM-G930T`).
      attr_reader :device
      # The platform for the browser session (e.g., `Macintosh`).
      attr_reader :platform
      # The version for the browser session (e.g., `61.0.3163.100`).
      attr_reader :version

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # The ZIP or postal code of the card used, if applicable.
    attr_reader :billing_zip
    # The charge associated with this review.
    attr_reader :charge
    # The reason the review was closed, or null if it has not yet been closed. One of `approved`, `refunded`, `refunded_as_fraud`, `disputed`, `redacted`, `canceled`, `payment_never_settled`, or `acknowledged`.
    attr_reader :closed_reason
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Unique identifier for the object.
    attr_reader :id
    # The IP address where the payment originated.
    attr_reader :ip_address
    # Information related to the location of the payment. Note that this information is an approximation and attempts to locate the nearest population center - it should not be used to determine a specific address.
    attr_reader :ip_address_location
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # If `true`, the review needs action.
    attr_reader :open
    # The reason the review was opened. One of `rule` or `manual`.
    attr_reader :opened_reason
    # The PaymentIntent ID associated with this review, if one exists.
    attr_reader :payment_intent
    # The reason the review is currently open or closed. One of `rule`, `manual`, `approved`, `refunded`, `refunded_as_fraud`, `disputed`, `redacted`, `canceled`, `payment_never_settled`, or `acknowledged`.
    attr_reader :reason
    # Information related to the browsing session of the user who initiated the payment.
    attr_reader :session

    # Approves a Review object, closing it and removing it from the list of reviews.
    def approve(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/reviews/%<review>s/approve", { review: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Approves a Review object, closing it and removing it from the list of reviews.
    def self.approve(review, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/reviews/%<review>s/approve", { review: CGI.escape(review) }),
        params: params,
        opts: opts
      )
    end

    # Returns a list of Review objects that have open set to true. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/reviews", params: params, opts: opts)
    end

    def self.inner_class_types
      @inner_class_types = { ip_address_location: IpAddressLocation, session: Session }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
