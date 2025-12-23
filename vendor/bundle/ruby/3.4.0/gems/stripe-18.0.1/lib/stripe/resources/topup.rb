# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # To top up your Stripe balance, you create a top-up object. You can retrieve
  # individual top-ups, as well as list all top-ups. Top-ups are identified by a
  # unique, random ID.
  #
  # Related guide: [Topping up your platform account](https://stripe.com/docs/connect/top-ups)
  class Topup < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "topup"
    def self.object_name
      "topup"
    end

    # Amount transferred.
    attr_reader :amount
    # ID of the balance transaction that describes the impact of this top-up on your account balance. May not be specified depending on status of top-up.
    attr_reader :balance_transaction
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_reader :description
    # Date the funds are expected to arrive in your Stripe account for payouts. This factors in delays like weekends or bank holidays. May not be specified depending on status of top-up.
    attr_reader :expected_availability_date
    # Error code explaining reason for top-up failure if available (see [the errors section](https://stripe.com/docs/api#errors) for a list of codes).
    attr_reader :failure_code
    # Message to user further explaining reason for top-up failure if available.
    attr_reader :failure_message
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The source field is deprecated. It might not always be present in the API response.
    attr_reader :source
    # Extra information about a top-up. This will appear on your source's bank statement. It must contain at least one letter.
    attr_reader :statement_descriptor
    # The status of the top-up is either `canceled`, `failed`, `pending`, `reversed`, or `succeeded`.
    attr_reader :status
    # A string that identifies this top-up as part of a group.
    attr_reader :transfer_group

    # Cancels a top-up. Only pending top-ups can be canceled.
    def cancel(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/topups/%<topup>s/cancel", { topup: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Cancels a top-up. Only pending top-ups can be canceled.
    def self.cancel(topup, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/topups/%<topup>s/cancel", { topup: CGI.escape(topup) }),
        params: params,
        opts: opts
      )
    end

    # Top up the balance of an account
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/topups", params: params, opts: opts)
    end

    # Returns a list of top-ups.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/topups", params: params, opts: opts)
    end

    # Updates the metadata of a top-up. Other top-up details are not editable by design.
    def self.update(topup, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/topups/%<topup>s", { topup: CGI.escape(topup) }),
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
