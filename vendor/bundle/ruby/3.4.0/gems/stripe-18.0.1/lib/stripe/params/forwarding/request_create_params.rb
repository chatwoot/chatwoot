# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Forwarding
    class RequestCreateParams < ::Stripe::RequestParams
      class Request < ::Stripe::RequestParams
        class Header < ::Stripe::RequestParams
          # The header name.
          attr_accessor :name
          # The header value.
          attr_accessor :value

          def initialize(name: nil, value: nil)
            @name = name
            @value = value
          end
        end
        # The body payload to send to the destination endpoint.
        attr_accessor :body
        # The headers to include in the forwarded request. Can be omitted if no additional headers (excluding Stripe-generated ones such as the Content-Type header) should be included.
        attr_accessor :headers

        def initialize(body: nil, headers: nil)
          @body = body
          @headers = headers
        end
      end
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The PaymentMethod to insert into the forwarded request. Forwarding previously consumed PaymentMethods is allowed.
      attr_accessor :payment_method
      # The field kinds to be replaced in the forwarded request.
      attr_accessor :replacements
      # The request body and headers to be sent to the destination endpoint.
      attr_accessor :request
      # The destination URL for the forwarded request. Must be supported by the config.
      attr_accessor :url

      def initialize(
        expand: nil,
        metadata: nil,
        payment_method: nil,
        replacements: nil,
        request: nil,
        url: nil
      )
        @expand = expand
        @metadata = metadata
        @payment_method = payment_method
        @replacements = replacements
        @request = request
        @url = url
      end
    end
  end
end
