# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SetupIntentService < StripeService
    # You can cancel a SetupIntent object when it's in one of these statuses: requires_payment_method, requires_confirmation, or requires_action.
    #
    # After you cancel it, setup is abandoned and any operations on the SetupIntent fail with an error. You can't cancel the SetupIntent for a Checkout Session. [Expire the Checkout Session](https://docs.stripe.com/docs/api/checkout/sessions/expire) instead.
    def cancel(intent, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/setup_intents/%<intent>s/cancel", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Confirm that your customer intends to set up the current or
    # provided payment method. For example, you would confirm a SetupIntent
    # when a customer hits the “Save” button on a payment method management
    # page on your website.
    #
    # If the selected payment method does not require any additional
    # steps from the customer, the SetupIntent will transition to the
    # succeeded status.
    #
    # Otherwise, it will transition to the requires_action status and
    # suggest additional actions via next_action. If setup fails,
    # the SetupIntent will transition to the
    # requires_payment_method status or the canceled status if the
    # confirmation limit is reached.
    def confirm(intent, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/setup_intents/%<intent>s/confirm", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Creates a SetupIntent object.
    #
    # After you create the SetupIntent, attach a payment method and [confirm](https://docs.stripe.com/docs/api/setup_intents/confirm)
    # it to collect any required permissions to charge the payment method later.
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/setup_intents",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of SetupIntents.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/setup_intents",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves the details of a SetupIntent that has previously been created.
    #
    # Client-side retrieval using a publishable key is allowed when the client_secret is provided in the query string.
    #
    # When retrieved with a publishable key, only a subset of properties will be returned. Please refer to the [SetupIntent](https://docs.stripe.com/api#setup_intent_object) object reference for more details.
    def retrieve(intent, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/setup_intents/%<intent>s", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates a SetupIntent object.
    def update(intent, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/setup_intents/%<intent>s", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Verifies microdeposits on a SetupIntent object.
    def verify_microdeposits(intent, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/setup_intents/%<intent>s/verify_microdeposits", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
