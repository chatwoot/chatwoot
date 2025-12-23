# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Clients
    module Graphql
      class Storefront < Client
        sig do
          params(
            shop: String,
            storefront_access_token: T.nilable(String),
            private_token: T.nilable(String),
            public_token: T.nilable(String),
            api_version: T.nilable(String),
          ).void
        end
        def initialize(shop, storefront_access_token = nil, private_token: nil, public_token: nil, api_version: nil)
          unless storefront_access_token.nil?
            warning = <<~WARNING
              DEPRECATED: Use the named parameters for the Storefront token instead of passing
              the public token as the second argument. Also, you may want to look into using
              the Storefront private access token instead:
              https://shopify.dev/docs/api/usage/authentication#getting-started-with-private-access
            WARNING
            ShopifyAPI::Logger.deprecated(warning, "15.0.0")
          end

          session = Auth::Session.new(
            id: shop,
            shop: shop,
            access_token: "",
            is_online: false,
          )
          super(session: session, base_path: "/api", api_version: api_version)
          @storefront_access_token = T.let(T.must(private_token || public_token || storefront_access_token), String)
          @storefront_auth_header = T.let(
            private_token.nil? ? "X-Shopify-Storefront-Access-Token" : "Shopify-Storefront-Private-Token",
            String,
          )
        end

        sig do
          params(
            query: String,
            variables: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]),
            headers: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]),
            tries: Integer,
            response_as_struct: T.nilable(T::Boolean),
            debug: T::Boolean,
          ).returns(HttpResponse)
        end
        def query(
          query:,
          variables: nil,
          headers: {},
          tries: 1,
          response_as_struct: Context.response_as_struct,
          debug: false
        )
          T.must(headers).merge!({ @storefront_auth_header => @storefront_access_token })
          super(query: query, variables: variables, headers: headers, tries: tries,
                    response_as_struct: response_as_struct, debug: debug)
        end
      end
    end
  end
end
