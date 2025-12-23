# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # `Application Fee Refund` objects allow you to refund an application fee that
  # has previously been created but not yet refunded. Funds will be refunded to
  # the Stripe account from which the fee was originally collected.
  #
  # Related guide: [Refunding application fees](https://stripe.com/docs/connect/destination-charges#refunding-app-fee)
  class ApplicationFeeRefund < APIResource
    include Stripe::APIOperations::Save

    OBJECT_NAME = "fee_refund"
    def self.object_name
      "fee_refund"
    end

    # Amount, in cents (or local equivalent).
    attr_reader :amount
    # Balance transaction that describes the impact on your account balance.
    attr_reader :balance_transaction
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # ID of the application fee that was refunded.
    attr_reader :fee
    # Unique identifier for the object.
    attr_reader :id
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object

    def resource_url
      "#{ApplicationFee.resource_url}/#{CGI.escape(fee)}/refunds" \
        "/#{CGI.escape(id)}"
    end

    def self.update(_id, _params = nil, _opts = nil)
      raise NotImplementedError,
            "Application fee refunds cannot be updated without an " \
            "application fee ID. Update an application fee refund using " \
            "`ApplicationFee.update_refund('fee_id', 'refund_id', " \
            "update_params)`"
    end

    def self.retrieve(_id, _api_key = nil)
      raise NotImplementedError,
            "Application fee refunds cannot be retrieved without an " \
            "application fee ID. Retrieve an application fee refund using " \
            "`ApplicationFee.retrieve_refund('fee_id', 'refund_id')`"
    end

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
