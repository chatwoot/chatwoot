# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Errors
    class HttpResponseError < StandardError
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :code

      sig { returns(ShopifyAPI::Clients::HttpResponse) }
      attr_reader :response

      sig { params(response: ShopifyAPI::Clients::HttpResponse).void }
      def initialize(response:)
        super
        @code = T.let(response.code, Integer)
        @response = response
      end
    end
  end
end
