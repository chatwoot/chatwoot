# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerService < StripeService
    attr_reader :balance_transactions, :cash_balance, :cash_balance_transactions, :funding_instructions, :payment_methods, :payment_sources, :tax_ids

    def initialize(requestor)
      super
      @balance_transactions = Stripe::CustomerBalanceTransactionService.new(@requestor)
      @cash_balance = Stripe::CustomerCashBalanceService.new(@requestor)
      @cash_balance_transactions = Stripe::CustomerCashBalanceTransactionService.new(@requestor)
      @funding_instructions = Stripe::CustomerFundingInstructionsService.new(@requestor)
      @payment_methods = Stripe::CustomerPaymentMethodService.new(@requestor)
      @payment_sources = Stripe::CustomerPaymentSourceService.new(@requestor)
      @tax_ids = Stripe::CustomerTaxIdService.new(@requestor)
    end

    # Creates a new customer object.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/customers", params: params, opts: opts, base_address: :api)
    end

    # Permanently deletes a customer. It cannot be undone. Also immediately cancels any active subscriptions on the customer.
    def delete(customer, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/customers/%<customer>s", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Removes the currently applied discount on a customer.
    def delete_discount(customer, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/customers/%<customer>s/discount", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of your customers. The customers are returned sorted by creation date, with the most recent customers appearing first.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/customers", params: params, opts: opts, base_address: :api)
    end

    # Retrieves a Customer object.
    def retrieve(customer, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/customers/%<customer>s", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Search for customers you've previously created using Stripe's [Search Query Language](https://docs.stripe.com/docs/search#search-query-language).
    # Don't use search in read-after-write flows where strict consistency is necessary. Under normal operating
    # conditions, data is searchable in less than a minute. Occasionally, propagation of new or updated data can be up
    # to an hour behind during outages. Search functionality is not available to merchants in India.
    def search(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/customers/search",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the specified customer by setting the values of the parameters passed. Any parameters not provided will be left unchanged. For example, if you pass the source parameter, that becomes the customer's active source (e.g., a card) to be used for all charges in the future. When you update a customer to a new valid card source by passing the source parameter: for each of the customer's current subscriptions, if the subscription bills automatically and is in the past_due state, then the latest open invoice for the subscription with automatic collection enabled will be retried. This retry will not count as an automatic retry, and will not affect the next regularly scheduled payment for the invoice. Changing the default_source for a customer will not trigger this behavior.
    #
    # This request accepts mostly the same arguments as the customer creation call.
    def update(customer, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/customers/%<customer>s", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
