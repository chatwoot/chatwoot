# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # A `Transfer` object is created when you move funds between Stripe accounts as
  # part of Connect.
  #
  # Before April 6, 2017, transfers also represented movement of funds from a
  # Stripe account to a card or bank account. This behavior has since been split
  # out into a [Payout](https://stripe.com/docs/api#payout_object) object, with corresponding payout endpoints. For more
  # information, read about the
  # [transfer/payout split](https://stripe.com/docs/transfer-payout-split).
  #
  # Related guide: [Creating separate charges and transfers](https://stripe.com/docs/connect/separate-charges-and-transfers)
  class Transfer < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    extend Stripe::APIOperations::NestedResource
    include Stripe::APIOperations::Save

    OBJECT_NAME = "transfer"
    def self.object_name
      "transfer"
    end

    nested_resource_class_methods :reversal, operations: %i[create retrieve update list]

    # Amount in cents (or local equivalent) to be transferred.
    attr_reader :amount
    # Amount in cents (or local equivalent) reversed (can be less than the amount attribute on the transfer if a partial reversal was issued).
    attr_reader :amount_reversed
    # Balance transaction that describes the impact of this transfer on your account balance.
    attr_reader :balance_transaction
    # Time that this record of the transfer was first created.
    attr_reader :created
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_reader :description
    # ID of the Stripe account the transfer was sent to.
    attr_reader :destination
    # If the destination is a Stripe account, this will be the ID of the payment that the destination account received for the transfer.
    attr_reader :destination_payment
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # A list of reversals that have been applied to the transfer.
    attr_reader :reversals
    # Whether the transfer has been fully reversed. If the transfer is only partially reversed, this attribute will still be false.
    attr_reader :reversed
    # ID of the charge that was used to fund the transfer. If null, the transfer was funded from the available balance.
    attr_reader :source_transaction
    # The source balance this transfer came from. One of `card`, `fpx`, or `bank_account`.
    attr_reader :source_type
    # A string that identifies this transaction as part of a group. See the [Connect documentation](https://stripe.com/docs/connect/separate-charges-and-transfers#transfer-options) for details.
    attr_reader :transfer_group

    # To send funds from your Stripe account to a connected account, you create a new transfer object. Your [Stripe balance](https://docs.stripe.com/api#balance) must be able to cover the transfer amount, or you'll receive an “Insufficient Funds” error.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/transfers", params: params, opts: opts)
    end

    # Returns a list of existing transfers sent to connected accounts. The transfers are returned in sorted order, with the most recently created transfers appearing first.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/transfers", params: params, opts: opts)
    end

    # Updates the specified transfer by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
    #
    # This request accepts only metadata as an argument.
    def self.update(transfer, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/transfers/%<transfer>s", { transfer: CGI.escape(transfer) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
