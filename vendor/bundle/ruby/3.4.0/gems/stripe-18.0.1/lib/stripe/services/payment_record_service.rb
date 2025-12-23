# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentRecordService < StripeService
    # Report a new Payment Record. You may report a Payment Record as it is
    #  initialized and later report updates through the other report_* methods, or report Payment
    #  Records in a terminal state directly, through this method.
    def report_payment(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/payment_records/report_payment",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Report a new payment attempt on the specified Payment Record. A new payment
    #  attempt can only be specified if all other payment attempts are canceled or failed.
    def report_payment_attempt(id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_records/%<id>s/report_payment_attempt", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Report that the most recent payment attempt on the specified Payment Record
    #  was canceled.
    def report_payment_attempt_canceled(id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_records/%<id>s/report_payment_attempt_canceled", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Report that the most recent payment attempt on the specified Payment Record
    #  failed or errored.
    def report_payment_attempt_failed(id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_records/%<id>s/report_payment_attempt_failed", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Report that the most recent payment attempt on the specified Payment Record
    #  was guaranteed.
    def report_payment_attempt_guaranteed(id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_records/%<id>s/report_payment_attempt_guaranteed", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Report informational updates on the specified Payment Record.
    def report_payment_attempt_informational(id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_records/%<id>s/report_payment_attempt_informational", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Report that the most recent payment attempt on the specified Payment Record
    #  was refunded.
    def report_refund(id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_records/%<id>s/report_refund", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves a Payment Record with the given ID
    def retrieve(id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/payment_records/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
