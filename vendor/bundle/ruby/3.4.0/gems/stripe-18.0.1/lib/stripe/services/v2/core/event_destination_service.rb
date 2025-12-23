# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module V2
    module Core
      class EventDestinationService < StripeService
        # Create a new event destination.
        def create(params = {}, opts = {})
          request(
            method: :post,
            path: "/v2/core/event_destinations",
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Delete an event destination.
        def delete(id, params = {}, opts = {})
          request(
            method: :delete,
            path: format("/v2/core/event_destinations/%<id>s", { id: CGI.escape(id) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Disable an event destination.
        def disable(id, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v2/core/event_destinations/%<id>s/disable", { id: CGI.escape(id) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Enable an event destination.
        def enable(id, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v2/core/event_destinations/%<id>s/enable", { id: CGI.escape(id) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Lists all event destinations.
        def list(params = {}, opts = {})
          request(
            method: :get,
            path: "/v2/core/event_destinations",
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Send a `ping` event to an event destination.
        def ping(id, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v2/core/event_destinations/%<id>s/ping", { id: CGI.escape(id) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Retrieves the details of an event destination.
        def retrieve(id, params = {}, opts = {})
          request(
            method: :get,
            path: format("/v2/core/event_destinations/%<id>s", { id: CGI.escape(id) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Update the details of an event destination.
        def update(id, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v2/core/event_destinations/%<id>s", { id: CGI.escape(id) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end
      end
    end
  end
end
