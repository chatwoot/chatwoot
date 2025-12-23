# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CreditNoteService < StripeService
    attr_reader :line_items, :preview_lines

    def initialize(requestor)
      super
      @line_items = Stripe::CreditNoteLineItemService.new(@requestor)
      @preview_lines = Stripe::CreditNotePreviewLinesService.new(@requestor)
    end

    # Issue a credit note to adjust the amount of a finalized invoice. A credit note will first reduce the invoice's amount_remaining (and amount_due), but not below zero.
    # This amount is indicated by the credit note's pre_payment_amount. The excess amount is indicated by post_payment_amount, and it can result in any combination of the following:
    #
    #
    # Refunds: create a new refund (using refund_amount) or link existing refunds (using refunds).
    # Customer balance credit: credit the customer's balance (using credit_amount) which will be automatically applied to their next invoice when it's finalized.
    # Outside of Stripe credit: record the amount that is or will be credited outside of Stripe (using out_of_band_amount).
    #
    #
    # The sum of refunds, customer balance credits, and outside of Stripe credits must equal the post_payment_amount.
    #
    # You may issue multiple credit notes for an invoice. Each credit note may increment the invoice's pre_payment_credit_notes_amount,
    # post_payment_credit_notes_amount, or both, depending on the invoice's amount_remaining at the time of credit note creation.
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/credit_notes",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of credit notes.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/credit_notes",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Get a preview of a credit note without creating it.
    def preview(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/credit_notes/preview",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves the credit note object with the given identifier.
    def retrieve(id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/credit_notes/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates an existing credit note.
    def update(id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/credit_notes/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Marks a credit note as void. Learn more about [voiding credit notes](https://docs.stripe.com/docs/billing/invoices/credit-notes#voiding).
    def void_credit_note(id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/credit_notes/%<id>s/void", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
