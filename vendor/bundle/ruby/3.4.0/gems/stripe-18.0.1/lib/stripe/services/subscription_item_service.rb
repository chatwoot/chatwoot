# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SubscriptionItemService < StripeService
    # Adds a new item to an existing subscription. No existing items will be changed or replaced.
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/subscription_items",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Deletes an item from the subscription. Removing a subscription item from a subscription will not cancel the subscription.
    def delete(item, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/subscription_items/%<item>s", { item: CGI.escape(item) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of your subscription items for a given subscription.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/subscription_items",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves the subscription item with the given ID.
    def retrieve(item, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/subscription_items/%<item>s", { item: CGI.escape(item) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the plan or quantity of an item on a current subscription.
    def update(item, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/subscription_items/%<item>s", { item: CGI.escape(item) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
