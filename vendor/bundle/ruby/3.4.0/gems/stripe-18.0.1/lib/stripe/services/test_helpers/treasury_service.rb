# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    class TreasuryService < StripeService
      attr_reader :inbound_transfers, :outbound_payments, :outbound_transfers, :received_credits, :received_debits

      def initialize(requestor)
        super
        @inbound_transfers = Stripe::TestHelpers::Treasury::InboundTransferService.new(@requestor)
        @outbound_payments = Stripe::TestHelpers::Treasury::OutboundPaymentService.new(@requestor)
        @outbound_transfers = Stripe::TestHelpers::Treasury::OutboundTransferService.new(@requestor)
        @received_credits = Stripe::TestHelpers::Treasury::ReceivedCreditService.new(@requestor)
        @received_debits = Stripe::TestHelpers::Treasury::ReceivedDebitService.new(@requestor)
      end
    end
  end
end
