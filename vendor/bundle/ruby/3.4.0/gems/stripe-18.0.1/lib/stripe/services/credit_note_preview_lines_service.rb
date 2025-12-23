# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CreditNotePreviewLinesService < StripeService
    # When retrieving a credit note preview, you'll get a lines property containing the first handful of those items. This URL you can retrieve the full (paginated) list of line items.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/credit_notes/preview/lines",
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
