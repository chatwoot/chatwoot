# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Rest
    class BaseErrors
      extend T::Sig

      sig { returns(T::Array[ShopifyAPI::Errors::HttpResponseError]) }
      attr_accessor :errors

      sig { void }
      def initialize
        @errors = T.let([], T::Array[ShopifyAPI::Errors::HttpResponseError])
      end

      sig { returns(String) }
      def full_messages
        @errors.join("\n")
      end

      sig { returns(T::Array[T.untyped]) }
      def codes
        codes = []
        @errors.each do |error|
          codes << error.code
        end
        codes
      end
    end
  end
end
