# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Each customer has a [Balance](https://stripe.com/docs/api/customers/object#customer_object-balance) value,
  # which denotes a debit or credit that's automatically applied to their next invoice upon finalization.
  # You may modify the value directly by using the [update customer API](https://stripe.com/docs/api/customers/update),
  # or by creating a Customer Balance Transaction, which increments or decrements the customer's `balance` by the specified `amount`.
  #
  # Related guide: [Customer balance](https://stripe.com/docs/billing/customer/balance)
  class CustomerBalanceTransaction < APIResource
    include Stripe::APIOperations::Save

    OBJECT_NAME = "customer_balance_transaction"
    def self.object_name
      "customer_balance_transaction"
    end

    # The amount of the transaction. A negative value is a credit for the customer's balance, and a positive value is a debit to the customer's `balance`.
    attr_reader :amount
    # The ID of the checkout session (if any) that created the transaction.
    attr_reader :checkout_session
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # The ID of the credit note (if any) related to the transaction.
    attr_reader :credit_note
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # The ID of the customer the transaction belongs to.
    attr_reader :customer
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_reader :description
    # The customer's `balance` after the transaction was applied. A negative value decreases the amount due on the customer's next invoice. A positive value increases the amount due on the customer's next invoice.
    attr_reader :ending_balance
    # Unique identifier for the object.
    attr_reader :id
    # The ID of the invoice (if any) related to the transaction.
    attr_reader :invoice
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Transaction type: `adjustment`, `applied_to_invoice`, `credit_note`, `initial`, `invoice_overpaid`, `invoice_too_large`, `invoice_too_small`, `unspent_receiver_credit`, `unapplied_from_invoice`, `checkout_session_subscription_payment`, or `checkout_session_subscription_payment_canceled`. See the [Customer Balance page](https://stripe.com/docs/billing/customer/balance#types) to learn more about transaction types.
    attr_reader :type

    def resource_url
      if !respond_to?(:customer) || customer.nil?
        raise NotImplementedError,
              "Customer Balance Transactions cannot be accessed without a customer ID."
      end
      "#{Customer.resource_url}/#{CGI.escape(customer)}/balance_transactions/#{CGI.escape(id)}"
    end

    def self.retrieve(_id, _opts = {})
      raise NotImplementedError,
            "Customer Balance Transactions cannot be retrieved without a customer ID. " \
            "Retrieve a Customer Balance Transaction using `Customer.retrieve_balance_transaction('cus_123', 'cbtxn_123')`"
    end

    def self.update(_id, _params = nil, _opts = nil)
      raise NotImplementedError,
            "Customer Balance Transactions cannot be retrieved without a customer ID. " \
            "Update a Customer Balance Transaction using `Customer.update_balance_transaction('cus_123', 'cbtxn_123', params)`"
    end

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
