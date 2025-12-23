# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Clients
    class HttpRequest < T::Struct
      extend T::Sig

      prop :http_method, Symbol
      prop :path, String
      prop :body, T.nilable(T.any(T::Hash[T.any(Symbol, String), T.untyped], String))
      prop :body_type, T.nilable(String)
      prop :query, T.nilable(T::Hash[T.any(Symbol, String), T.untyped])
      prop :extra_headers, T.nilable(T::Hash[T.any(Symbol, String), T.untyped])
      prop :tries, Integer, default: 1

      sig { void }
      def verify
        unless [:get, :delete, :put, :post].include?(http_method)
          raise ShopifyAPI::Errors::InvalidHttpRequestError, "Invalid Http method #{http_method}."
        end

        if body && !body_type
          raise ShopifyAPI::Errors::InvalidHttpRequestError, "Cannot set a body without also setting body_type."
        end

        return unless [:put, :post].include?(http_method)

        unless  body
          raise ShopifyAPI::Errors::InvalidHttpRequestError, "Cannot use #{http_method} without specifying data."
        end
      end
    end
  end
end
