# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # [Stripe Connect](https://stripe.com/docs/connect) platforms can reverse transfers made to a
  # connected account, either entirely or partially, and can also specify whether
  # to refund any related application fees. Transfer reversals add to the
  # platform's balance and subtract from the destination account's balance.
  #
  # Reversing a transfer that was made for a [destination
  # charge](https://docs.stripe.com/docs/connect/destination-charges) is allowed only up to the amount of
  # the charge. It is possible to reverse a
  # [transfer_group](https://stripe.com/docs/connect/separate-charges-and-transfers#transfer-options)
  # transfer only if the destination account has enough balance to cover the
  # reversal.
  #
  # Related guide: [Reverse transfers](https://stripe.com/docs/connect/separate-charges-and-transfers#reverse-transfers)
  class Reversal < APIResource
    include Stripe::APIOperations::Save

    OBJECT_NAME = "transfer_reversal"
    def self.object_name
      "transfer_reversal"
    end

    # Amount, in cents (or local equivalent).
    attr_reader :amount
    # Balance transaction that describes the impact on your account balance.
    attr_reader :balance_transaction
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # Linked payment refund for the transfer reversal.
    attr_reader :destination_payment_refund
    # Unique identifier for the object.
    attr_reader :id
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # ID of the refund responsible for the transfer reversal.
    attr_reader :source_refund
    # ID of the transfer that was reversed.
    attr_reader :transfer

    def resource_url
      "#{Transfer.resource_url}/#{CGI.escape(transfer)}/reversals" \
        "/#{CGI.escape(id)}"
    end

    def self.update(_id, _params = nil, _opts = nil)
      raise NotImplementedError,
            "Reversals cannot be updated without a transfer ID. Update a " \
            "reversal using `r = Transfer.update_reversal('transfer_id', " \
            "'reversal_id', update_params)`"
    end

    def self.retrieve(_id, _opts = {})
      raise NotImplementedError,
            "Reversals cannot be retrieved without a transfer ID. Retrieve " \
            "a reversal using `Transfer.retrieve_reversal('transfer_id', " \
            "'reversal_id'`"
    end

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
