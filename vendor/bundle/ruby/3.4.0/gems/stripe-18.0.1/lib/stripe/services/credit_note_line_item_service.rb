# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CreditNoteLineItemService < StripeService
    # When retrieving a credit note, you'll get a lines property containing the first handful of those items. There is also a URL where you can retrieve the full (paginated) list of line items.
    def list(credit_note, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/credit_notes/%<credit_note>s/lines", { credit_note: CGI.escape(credit_note) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
