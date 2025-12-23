# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ChargeService < StripeService
    # Capture the payment of an existing, uncaptured charge that was created with the capture option set to false.
    #
    # Uncaptured payments expire a set number of days after they are created ([7 by default](https://docs.stripe.com/docs/charges/placing-a-hold)), after which they are marked as refunded and capture attempts will fail.
    #
    # Don't use this method to capture a PaymentIntent-initiated charge. Use [Capture a PaymentIntent](https://docs.stripe.com/docs/api/payment_intents/capture).
    def capture(charge, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/charges/%<charge>s/capture", { charge: CGI.escape(charge) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # This method is no longer recommended—use the [Payment Intents API](https://docs.stripe.com/docs/api/payment_intents)
    # to initiate a new payment instead. Confirmation of the PaymentIntent creates the Charge
    # object used to request payment.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/charges", params: params, opts: opts, base_address: :api)
    end

    # Returns a list of charges you've previously created. The charges are returned in sorted order, with the most recent charges appearing first.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/charges", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the details of a charge that has previously been created. Supply the unique charge ID that was returned from your previous request, and Stripe will return the corresponding charge information. The same information is returned when creating or refunding the charge.
    def retrieve(charge, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/charges/%<charge>s", { charge: CGI.escape(charge) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Search for charges you've previously created using Stripe's [Search Query Language](https://docs.stripe.com/docs/search#search-query-language).
    # Don't use search in read-after-write flows where strict consistency is necessary. Under normal operating
    # conditions, data is searchable in less than a minute. Occasionally, propagation of new or updated data can be up
    # to an hour behind during outages. Search functionality is not available to merchants in India.
    def search(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/charges/search",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the specified charge by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
    def update(charge, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/charges/%<charge>s", { charge: CGI.escape(charge) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
