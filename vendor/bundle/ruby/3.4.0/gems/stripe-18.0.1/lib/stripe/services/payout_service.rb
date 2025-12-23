# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PayoutService < StripeService
    # You can cancel a previously created payout if its status is pending. Stripe refunds the funds to your available balance. You can't cancel automatic Stripe payouts.
    def cancel(payout, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payouts/%<payout>s/cancel", { payout: CGI.escape(payout) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # To send funds to your own bank account, create a new payout object. Your [Stripe balance](https://docs.stripe.com/api#balance) must cover the payout amount. If it doesn't, you receive an “Insufficient Funds” error.
    #
    # If your API key is in test mode, money won't actually be sent, though every other action occurs as if you're in live mode.
    #
    # If you create a manual payout on a Stripe account that uses multiple payment source types, you need to specify the source type balance that the payout draws from. The [balance object](https://docs.stripe.com/api#balance_object) details available and pending amounts by source type.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/payouts", params: params, opts: opts, base_address: :api)
    end

    # Returns a list of existing payouts sent to third-party bank accounts or payouts that Stripe sent to you. The payouts return in sorted order, with the most recently created payouts appearing first.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/payouts", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the details of an existing payout. Supply the unique payout ID from either a payout creation request or the payout list. Stripe returns the corresponding payout information.
    def retrieve(payout, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/payouts/%<payout>s", { payout: CGI.escape(payout) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Reverses a payout by debiting the destination bank account. At this time, you can only reverse payouts for connected accounts to US and Canadian bank accounts. If the payout is manual and in the pending status, use /v1/payouts/:id/cancel instead.
    #
    # By requesting a reversal through /v1/payouts/:id/reverse, you confirm that the authorized signatory of the selected bank account authorizes the debit on the bank account and that no other authorization is required.
    def reverse(payout, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payouts/%<payout>s/reverse", { payout: CGI.escape(payout) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the specified payout by setting the values of the parameters you pass. We don't change parameters that you don't provide. This request only accepts the metadata as arguments.
    def update(payout, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payouts/%<payout>s", { payout: CGI.escape(payout) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
