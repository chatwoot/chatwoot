# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Forwarding
    # Instructs Stripe to make a request on your behalf using the destination URL. The destination URL
    # is activated by Stripe at the time of onboarding. Stripe verifies requests with your credentials
    # provided during onboarding, and injects card details from the payment_method into the request.
    #
    # Stripe redacts all sensitive fields and headers, including authentication credentials and card numbers,
    # before storing the request and response data in the forwarding Request object, which are subject to a
    # 30-day retention period.
    #
    # You can provide a Stripe idempotency key to make sure that requests with the same key result in only one
    # outbound request. The Stripe idempotency key provided should be unique and different from any idempotency
    # keys provided on the underlying third-party request.
    #
    # Forwarding Requests are synchronous requests that return a response or time out according to
    # Stripe's limits.
    #
    # Related guide: [Forward card details to third-party API endpoints](https://docs.stripe.com/payments/forwarding).
    class Request < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List

      OBJECT_NAME = "forwarding.request"
      def self.object_name
        "forwarding.request"
      end

      class RequestContext < ::Stripe::StripeObject
        # The time it took in milliseconds for the destination endpoint to respond.
        attr_reader :destination_duration
        # The IP address of the destination.
        attr_reader :destination_ip_address

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class RequestDetails < ::Stripe::StripeObject
        class Header < ::Stripe::StripeObject
          # The header name.
          attr_reader :name
          # The header value.
          attr_reader :value

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The body payload to send to the destination endpoint.
        attr_reader :body
        # The headers to include in the forwarded request. Can be omitted if no additional headers (excluding Stripe-generated ones such as the Content-Type header) should be included.
        attr_reader :headers
        # The HTTP method used to call the destination endpoint.
        attr_reader :http_method

        def self.inner_class_types
          @inner_class_types = { headers: Header }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class ResponseDetails < ::Stripe::StripeObject
        class Header < ::Stripe::StripeObject
          # The header name.
          attr_reader :name
          # The header value.
          attr_reader :value

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The response body from the destination endpoint to Stripe.
        attr_reader :body
        # HTTP headers that the destination endpoint returned.
        attr_reader :headers
        # The HTTP status code that the destination endpoint returned.
        attr_reader :status

        def self.inner_class_types
          @inner_class_types = { headers: Header }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The PaymentMethod to insert into the forwarded request. Forwarding previously consumed PaymentMethods is allowed.
      attr_reader :payment_method
      # The field kinds to be replaced in the forwarded request.
      attr_reader :replacements
      # Context about the request from Stripe's servers to the destination endpoint.
      attr_reader :request_context
      # The request that was sent to the destination endpoint. We redact any sensitive fields.
      attr_reader :request_details
      # The response that the destination endpoint returned to us. We redact any sensitive fields.
      attr_reader :response_details
      # The destination URL for the forwarded request. Must be supported by the config.
      attr_reader :url

      # Creates a ForwardingRequest object.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/forwarding/requests",
          params: params,
          opts: opts
        )
      end

      # Lists all ForwardingRequest objects.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/forwarding/requests",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = {
          request_context: RequestContext,
          request_details: RequestDetails,
          response_details: ResponseDetails,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
