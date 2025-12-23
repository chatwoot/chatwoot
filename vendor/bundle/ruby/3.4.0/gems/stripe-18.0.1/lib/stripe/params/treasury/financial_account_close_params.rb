# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class FinancialAccountCloseParams < ::Stripe::RequestParams
      class ForwardingSettings < ::Stripe::RequestParams
        # The financial_account id
        attr_accessor :financial_account
        # The payment_method or bank account id. This needs to be a verified bank account.
        attr_accessor :payment_method
        # The type of the bank account provided. This can be either "financial_account" or "payment_method"
        attr_accessor :type

        def initialize(financial_account: nil, payment_method: nil, type: nil)
          @financial_account = financial_account
          @payment_method = payment_method
          @type = type
        end
      end
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # A different bank account where funds can be deposited/debited in order to get the closing FA's balance to $0
      attr_accessor :forwarding_settings

      def initialize(expand: nil, forwarding_settings: nil)
        @expand = expand
        @forwarding_settings = forwarding_settings
      end
    end
  end
end
