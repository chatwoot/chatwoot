# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ConnectCollectionTransfer < APIResource
    OBJECT_NAME = "connect_collection_transfer"
    def self.object_name
      "connect_collection_transfer"
    end

    # Amount transferred, in cents (or local equivalent).
    attr_reader :amount
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # ID of the account that funds are being collected for.
    attr_reader :destination
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
