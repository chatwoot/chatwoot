# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ChargeCaptureParams < ::Stripe::RequestParams
    class TransferData < ::Stripe::RequestParams
      # The amount transferred to the destination account, if specified. By default, the entire charge amount is transferred to the destination account.
      attr_accessor :amount

      def initialize(amount: nil)
        @amount = amount
      end
    end
    # The amount to capture, which must be less than or equal to the original amount.
    attr_accessor :amount
    # An application fee to add on to this charge.
    attr_accessor :application_fee
    # An application fee amount to add on to this charge, which must be less than or equal to the original amount.
    attr_accessor :application_fee_amount
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # The email address to send this charge's receipt to. This will override the previously-specified email address for this charge, if one was set. Receipts will not be sent in test mode.
    attr_accessor :receipt_email
    # For a non-card charge, text that appears on the customer's statement as the statement descriptor. This value overrides the account's default statement descriptor. For information about requirements, including the 22-character limit, see [the Statement Descriptor docs](https://docs.stripe.com/get-started/account/statement-descriptors).
    #
    # For a card charge, this value is ignored unless you don't specify a `statement_descriptor_suffix`, in which case this value is used as the suffix.
    attr_accessor :statement_descriptor
    # Provides information about a card charge. Concatenated to the account's [statement descriptor prefix](https://docs.stripe.com/get-started/account/statement-descriptors#static) to form the complete statement descriptor that appears on the customer's statement. If the account has no prefix value, the suffix is concatenated to the account's statement descriptor.
    attr_accessor :statement_descriptor_suffix
    # An optional dictionary including the account to automatically transfer to as part of a destination charge. [See the Connect documentation](https://stripe.com/docs/connect/destination-charges) for details.
    attr_accessor :transfer_data
    # A string that identifies this transaction as part of a group. `transfer_group` may only be provided if it has not been set. See the [Connect documentation](https://stripe.com/docs/connect/separate-charges-and-transfers#transfer-options) for details.
    attr_accessor :transfer_group

    def initialize(
      amount: nil,
      application_fee: nil,
      application_fee_amount: nil,
      expand: nil,
      receipt_email: nil,
      statement_descriptor: nil,
      statement_descriptor_suffix: nil,
      transfer_data: nil,
      transfer_group: nil
    )
      @amount = amount
      @application_fee = application_fee
      @application_fee_amount = application_fee_amount
      @expand = expand
      @receipt_email = receipt_email
      @statement_descriptor = statement_descriptor
      @statement_descriptor_suffix = statement_descriptor_suffix
      @transfer_data = transfer_data
      @transfer_group = transfer_group
    end
  end
end
