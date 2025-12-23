# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentMethodService < StripeService
    # Attaches a PaymentMethod object to a Customer.
    #
    # To attach a new PaymentMethod to a customer for future payments, we recommend you use a [SetupIntent](https://docs.stripe.com/docs/api/setup_intents)
    # or a PaymentIntent with [setup_future_usage](https://docs.stripe.com/docs/api/payment_intents/create#create_payment_intent-setup_future_usage).
    # These approaches will perform any necessary steps to set up the PaymentMethod for future payments. Using the /v1/payment_methods/:id/attach
    # endpoint without first using a SetupIntent or PaymentIntent with setup_future_usage does not optimize the PaymentMethod for
    # future use, which makes later declines and payment friction more likely.
    # See [Optimizing cards for future payments](https://docs.stripe.com/docs/payments/payment-intents#future-usage) for more information about setting up
    # future payments.
    #
    # To use this PaymentMethod as the default for invoice or subscription payments,
    # set [invoice_settings.default_payment_method](https://docs.stripe.com/docs/api/customers/update#update_customer-invoice_settings-default_payment_method),
    # on the Customer to the PaymentMethod's ID.
    def attach(payment_method, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_methods/%<payment_method>s/attach", { payment_method: CGI.escape(payment_method) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Creates a PaymentMethod object. Read the [Stripe.js reference](https://docs.stripe.com/docs/stripe-js/reference#stripe-create-payment-method) to learn how to create PaymentMethods via Stripe.js.
    #
    # Instead of creating a PaymentMethod directly, we recommend using the [PaymentIntents API to accept a payment immediately or the <a href="/docs/payments/save-and-reuse">SetupIntent](https://docs.stripe.com/docs/payments/accept-a-payment) API to collect payment method details ahead of a future payment.
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/payment_methods",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Detaches a PaymentMethod object from a Customer. After a PaymentMethod is detached, it can no longer be used for a payment or re-attached to a Customer.
    def detach(payment_method, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_methods/%<payment_method>s/detach", { payment_method: CGI.escape(payment_method) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of PaymentMethods for Treasury flows. If you want to list the PaymentMethods attached to a Customer for payments, you should use the [List a Customer's PaymentMethods](https://docs.stripe.com/docs/api/payment_methods/customer_list) API instead.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/payment_methods",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves a PaymentMethod object attached to the StripeAccount. To retrieve a payment method attached to a Customer, you should use [Retrieve a Customer's PaymentMethods](https://docs.stripe.com/docs/api/payment_methods/customer)
    def retrieve(payment_method, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/payment_methods/%<payment_method>s", { payment_method: CGI.escape(payment_method) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates a PaymentMethod object. A PaymentMethod must be attached to a customer to be updated.
    def update(payment_method, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_methods/%<payment_method>s", { payment_method: CGI.escape(payment_method) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
