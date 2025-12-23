# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TopupCreateParams < ::Stripe::RequestParams
    # A positive integer representing how much to transfer.
    attr_accessor :amount
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_accessor :currency
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_accessor :description
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # The ID of a source to transfer funds from. For most users, this should be left unspecified which will use the bank account that was set up in the dashboard for the specified currency. In test mode, this can be a test bank token (see [Testing Top-ups](https://stripe.com/docs/connect/testing#testing-top-ups)).
    attr_accessor :source
    # Extra information about a top-up for the source's bank statement. Limited to 15 ASCII characters.
    attr_accessor :statement_descriptor
    # A string that identifies this top-up as part of a group.
    attr_accessor :transfer_group

    def initialize(
      amount: nil,
      currency: nil,
      description: nil,
      expand: nil,
      metadata: nil,
      source: nil,
      statement_descriptor: nil,
      transfer_group: nil
    )
      @amount = amount
      @currency = currency
      @description = description
      @expand = expand
      @metadata = metadata
      @source = source
      @statement_descriptor = statement_descriptor
      @transfer_group = transfer_group
    end
  end
end
