# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TreasuryService < StripeService
    attr_reader :credit_reversals, :debit_reversals, :financial_accounts, :inbound_transfers, :outbound_payments, :outbound_transfers, :received_credits, :received_debits, :transactions, :transaction_entries

    def initialize(requestor)
      super
      @credit_reversals = Stripe::Treasury::CreditReversalService.new(@requestor)
      @debit_reversals = Stripe::Treasury::DebitReversalService.new(@requestor)
      @financial_accounts = Stripe::Treasury::FinancialAccountService.new(@requestor)
      @inbound_transfers = Stripe::Treasury::InboundTransferService.new(@requestor)
      @outbound_payments = Stripe::Treasury::OutboundPaymentService.new(@requestor)
      @outbound_transfers = Stripe::Treasury::OutboundTransferService.new(@requestor)
      @received_credits = Stripe::Treasury::ReceivedCreditService.new(@requestor)
      @received_debits = Stripe::Treasury::ReceivedDebitService.new(@requestor)
      @transactions = Stripe::Treasury::TransactionService.new(@requestor)
      @transaction_entries = Stripe::Treasury::TransactionEntryService.new(@requestor)
    end
  end
end
