# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ConfigurationService < StripeService
      # Creates a new Configuration object.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/terminal/configurations",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Deletes a Configuration object.
      def delete(configuration, params = {}, opts = {})
        request(
          method: :delete,
          path: format("/v1/terminal/configurations/%<configuration>s", { configuration: CGI.escape(configuration) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of Configuration objects.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/terminal/configurations",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a Configuration object.
      def retrieve(configuration, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/terminal/configurations/%<configuration>s", { configuration: CGI.escape(configuration) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates a new Configuration object.
      def update(configuration, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/terminal/configurations/%<configuration>s", { configuration: CGI.escape(configuration) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
