# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class FinancialConnectionsService < StripeService
    attr_reader :accounts, :sessions, :transactions

    def initialize(requestor)
      super
      @accounts = Stripe::FinancialConnections::AccountService.new(@requestor)
      @sessions = Stripe::FinancialConnections::SessionService.new(@requestor)
      @transactions = Stripe::FinancialConnections::TransactionService.new(@requestor)
    end
  end
end
