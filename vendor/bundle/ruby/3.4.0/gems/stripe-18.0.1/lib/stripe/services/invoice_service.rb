# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class InvoiceService < StripeService
    attr_reader :line_items

    def initialize(requestor)
      super
      @line_items = Stripe::InvoiceLineItemService.new(@requestor)
    end

    # Adds multiple line items to an invoice. This is only possible when an invoice is still a draft.
    def add_lines(invoice, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/invoices/%<invoice>s/add_lines", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Attaches a PaymentIntent or an Out of Band Payment to the invoice, adding it to the list of payments.
    #
    # For the PaymentIntent, when the PaymentIntent's status changes to succeeded, the payment is credited
    # to the invoice, increasing its amount_paid. When the invoice is fully paid, the
    # invoice's status becomes paid.
    #
    # If the PaymentIntent's status is already succeeded when it's attached, it's
    # credited to the invoice immediately.
    #
    # See: [Partial payments](https://docs.stripe.com/docs/invoicing/partial-payments) to learn more.
    def attach_payment(invoice, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/invoices/%<invoice>s/attach_payment", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # This endpoint creates a draft invoice for a given customer. The invoice remains a draft until you [finalize the invoice, which allows you to [pay](#pay_invoice) or <a href="#send_invoice">send](https://docs.stripe.com/api#finalize_invoice) the invoice to your customers.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/invoices", params: params, opts: opts, base_address: :api)
    end

    # At any time, you can preview the upcoming invoice for a subscription or subscription schedule. This will show you all the charges that are pending, including subscription renewal charges, invoice item charges, etc. It will also show you any discounts that are applicable to the invoice.
    #
    # You can also preview the effects of creating or updating a subscription or subscription schedule, including a preview of any prorations that will take place. To ensure that the actual proration is calculated exactly the same as the previewed proration, you should pass the subscription_details.proration_date parameter when doing the actual subscription update.
    #
    # The recommended way to get only the prorations being previewed on the invoice is to consider line items where parent.subscription_item_details.proration is true.
    #
    # Note that when you are viewing an upcoming invoice, you are simply viewing a preview – the invoice has not yet been created. As such, the upcoming invoice will not show up in invoice listing calls, and you cannot use the API to pay or edit the invoice. If you want to change the amount that your customer will be billed, you can add, remove, or update pending invoice items, or update the customer's discount.
    #
    # Note: Currency conversion calculations use the latest exchange rates. Exchange rates may vary between the time of the preview and the time of the actual invoice creation. [Learn more](https://docs.stripe.com/currencies/conversions)
    def create_preview(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/invoices/create_preview",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Permanently deletes a one-off invoice draft. This cannot be undone. Attempts to delete invoices that are no longer in a draft state will fail; once an invoice has been finalized or if an invoice is for a subscription, it must be [voided](https://docs.stripe.com/api#void_invoice).
    def delete(invoice, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/invoices/%<invoice>s", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Stripe automatically finalizes drafts before sending and attempting payment on invoices. However, if you'd like to finalize a draft invoice manually, you can do so using this method.
    def finalize_invoice(invoice, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/invoices/%<invoice>s/finalize", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # You can list all invoices, or list the invoices for a specific customer. The invoices are returned sorted by creation date, with the most recently created invoices appearing first.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/invoices", params: params, opts: opts, base_address: :api)
    end

    # Marking an invoice as uncollectible is useful for keeping track of bad debts that can be written off for accounting purposes.
    def mark_uncollectible(invoice, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/invoices/%<invoice>s/mark_uncollectible", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Stripe automatically creates and then attempts to collect payment on invoices for customers on subscriptions according to your [subscriptions settings](https://dashboard.stripe.com/account/billing/automatic). However, if you'd like to attempt payment on an invoice out of the normal collection schedule or for some other reason, you can do so.
    def pay(invoice, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/invoices/%<invoice>s/pay", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Removes multiple line items from an invoice. This is only possible when an invoice is still a draft.
    def remove_lines(invoice, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/invoices/%<invoice>s/remove_lines", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves the invoice with the given ID.
    def retrieve(invoice, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/invoices/%<invoice>s", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Search for invoices you've previously created using Stripe's [Search Query Language](https://docs.stripe.com/docs/search#search-query-language).
    # Don't use search in read-after-write flows where strict consistency is necessary. Under normal operating
    # conditions, data is searchable in less than a minute. Occasionally, propagation of new or updated data can be up
    # to an hour behind during outages. Search functionality is not available to merchants in India.
    def search(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/invoices/search",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Stripe will automatically send invoices to customers according to your [subscriptions settings](https://dashboard.stripe.com/account/billing/automatic). However, if you'd like to manually send an invoice to your customer out of the normal schedule, you can do so. When sending invoices that have already been paid, there will be no reference to the payment in the email.
    #
    # Requests made in test-mode result in no emails being sent, despite sending an invoice.sent event.
    def send_invoice(invoice, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/invoices/%<invoice>s/send", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Draft invoices are fully editable. Once an invoice is [finalized](https://docs.stripe.com/docs/billing/invoices/workflow#finalized),
    # monetary values, as well as collection_method, become uneditable.
    #
    # If you would like to stop the Stripe Billing engine from automatically finalizing, reattempting payments on,
    # sending reminders for, or [automatically reconciling](https://docs.stripe.com/docs/billing/invoices/reconciliation) invoices, pass
    # auto_advance=false.
    def update(invoice, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/invoices/%<invoice>s", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates multiple line items on an invoice. This is only possible when an invoice is still a draft.
    def update_lines(invoice, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/invoices/%<invoice>s/update_lines", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Mark a finalized invoice as void. This cannot be undone. Voiding an invoice is similar to [deletion](https://docs.stripe.com/api#delete_invoice), however it only applies to finalized invoices and maintains a papertrail where the invoice can still be found.
    #
    # Consult with local regulations to determine whether and how an invoice might be amended, canceled, or voided in the jurisdiction you're doing business in. You might need to [issue another invoice or <a href="#create_credit_note">credit note](https://docs.stripe.com/api#create_invoice) instead. Stripe recommends that you consult with your legal counsel for advice specific to your business.
    def void_invoice(invoice, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/invoices/%<invoice>s/void", { invoice: CGI.escape(invoice) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
