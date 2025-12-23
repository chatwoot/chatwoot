# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Webhooks
    module Registrations
      class Http < Registration
        extend T::Sig

        sig { override.returns(String) }
        def callback_address
          if @path.match?(%r{^https?://})
            @path
          elsif @path.match?(/^#{Context.host_name}/)
            "#{Context.host_scheme}://#{@path}"
          else
            "#{Context.host}/#{@path}"
          end
        end

        sig { override.returns(T::Hash[Symbol, String]) }
        def subscription_args
          { callbackUrl: callback_address, includeFields: fields,
            metafieldNamespaces: metafield_namespaces, filter: filter, }.compact
        end

        sig { override.params(webhook_id: T.nilable(String)).returns(String) }
        def mutation_name(webhook_id)
          webhook_id ? "webhookSubscriptionUpdate" : "webhookSubscriptionCreate"
        end

        sig { override.returns(String) }
        def build_check_query
          <<~QUERY
            {
              webhookSubscriptions(first: 1, topics: #{@topic}) {
                edges {
                  node {
                    id
                    includeFields
                    metafieldNamespaces
                    filter
                    endpoint {
                      __typename
                      ... on WebhookHttpEndpoint {
                        callbackUrl
                      }
                    }
                  }
                }
              }
            }
          QUERY
        end

        sig do
          override.params(body: T::Hash[String, T.untyped]).returns({
            webhook_id: T.nilable(String),
            current_address: T.nilable(String),
            fields: T::Array[String],
            metafield_namespaces: T::Array[String],
            filter: T.nilable(String),
          })
        end
        def parse_check_result(body)
          edges = body.dig("data", "webhookSubscriptions", "edges") || {}
          webhook_id = nil
          fields = []
          metafield_namespaces = []
          filter = nil
          current_address = nil
          unless edges.empty?
            node = edges[0]["node"]
            webhook_id = node["id"].to_s
            current_address =
              if node.key?("endpoint")
                node["endpoint"]["callbackUrl"].to_s
              else
                node["callbackUrl"].to_s
              end
            fields = node["includeFields"] || []
            metafield_namespaces = node["metafieldNamespaces"] || []
            filter = node["filter"].to_s
          end
          { webhook_id: webhook_id, current_address: current_address, fields: fields,
            metafield_namespaces: metafield_namespaces, filter: filter, }
        end
      end
    end
  end
end
