# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Utils
    module GraphqlProxy
      class << self
        extend T::Sig

        sig do
          params(
            session: Auth::Session,
            headers: T::Hash[String, T.untyped],
            body: String,
            cookies: T.nilable(T::Hash[String, String]),
            tries: Integer,
          ).returns(Clients::HttpResponse)
        end
        def proxy_query(session:, headers:, body:, cookies: nil, tries: 1)
          raise Errors::PrivateAppError, "GraphQL proxing is unsupported for private apps." if Context.private?

          normalized_headers = HttpUtils.normalize_headers(headers)

          unless session.online?
            raise Errors::SessionNotFoundError,
              "Failed to load an online session from the provided parameters."
          end

          client = Clients::Graphql::Admin.new(session: session)

          case normalized_headers["content-type"]
          when "application/graphql"
            return client.query(query: body, tries: tries)
          when "application/json"
            parsed_body = JSON.parse(body)

            query = parsed_body["query"]
            raise Errors::InvalidGraphqlRequestError,
              "Request missing 'query' field in GraphQL proxy request." if query.nil?

            return client.query(query: query, variables: parsed_body["variables"], tries: tries)
          end

          raise Errors::InvalidGraphqlRequestError, "Unsupported Content-Type #{normalized_headers["content-type"]}."
        end
      end
    end
  end
end
