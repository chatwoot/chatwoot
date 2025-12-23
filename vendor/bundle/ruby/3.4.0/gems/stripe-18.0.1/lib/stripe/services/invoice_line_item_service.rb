# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class InvoiceLineItemService < StripeService
    # When retrieving an invoice, you'll get a lines property containing the total count of line items and the first handful of those items. There is also a URL where you can retrieve the full (paginated) list of line items.
    def list(invoice, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/invoices/%<invoice>s/lines", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates an invoice's line item. Some fields, such as tax_amounts, only live on the invoice line item,
    # so they can only be updated through this endpoint. Other fields, such as amount, live on both the invoice
    # item and the invoice line item, so updates on this endpoint will propagate to the invoice item as well.
    # Updating an invoice's line item is only possible before the invoice is finalized.
    def update(invoice, line_item_id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/invoices/%<invoice>s/lines/%<line_item_id>s", { invoice: CGI.escape(invoice), line_item_id: CGI.escape(line_item_id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
