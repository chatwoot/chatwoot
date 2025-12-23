# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentMethodDomainService < StripeService
    # Creates a payment method domain.
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/payment_method_domains",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Lists the details of existing payment method domains.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/payment_method_domains",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves the details of an existing payment method domain.
    def retrieve(payment_method_domain, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/payment_method_domains/%<payment_method_domain>s", { payment_method_domain: CGI.escape(payment_method_domain) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates an existing payment method domain.
    def update(payment_method_domain, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_method_domains/%<payment_method_domain>s", { payment_method_domain: CGI.escape(payment_method_domain) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Some payment methods might require additional steps to register a domain. If the requirements weren't satisfied when the domain was created, the payment method will be inactive on the domain.
    # The payment method doesn't appear in Elements or Embedded Checkout for this domain until it is active.
    #
    # To activate a payment method on an existing payment method domain, complete the required registration steps specific to the payment method, and then validate the payment method domain with this endpoint.
    #
    # Related guides: [Payment method domains](https://docs.stripe.com/docs/payments/payment-methods/pmd-registration).
    def validate(payment_method_domain, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_method_domains/%<payment_method_domain>s/validate", { payment_method_domain: CGI.escape(payment_method_domain) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
