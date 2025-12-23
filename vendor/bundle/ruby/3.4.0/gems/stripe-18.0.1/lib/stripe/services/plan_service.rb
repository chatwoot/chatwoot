# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PlanService < StripeService
    # You can now model subscriptions more flexibly using the [Prices API](https://docs.stripe.com/api#prices). It replaces the Plans API and is backwards compatible to simplify your migration.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/plans", params: params, opts: opts, base_address: :api)
    end

    # Deleting plans means new subscribers can't be added. Existing subscribers aren't affected.
    def delete(plan, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/plans/%<plan>s", { plan: CGI.escape(plan) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of your plans.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/plans", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the plan with the given ID.
    def retrieve(plan, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/plans/%<plan>s", { plan: CGI.escape(plan) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the specified plan by setting the values of the parameters passed. Any parameters not provided are left unchanged. By design, you cannot change a plan's ID, amount, currency, or billing cycle.
    def update(plan, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/plans/%<plan>s", { plan: CGI.escape(plan) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
