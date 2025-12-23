# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class BillingService < StripeService
    attr_reader :alerts, :credit_balance_summary, :credit_balance_transactions, :credit_grants, :meters, :meter_events, :meter_event_adjustments

    def initialize(requestor)
      super
      @alerts = Stripe::Billing::AlertService.new(@requestor)
      @credit_balance_summary = Stripe::Billing::CreditBalanceSummaryService.new(@requestor)
      @credit_balance_transactions = Stripe::Billing::CreditBalanceTransactionService
                                     .new(@requestor)
      @credit_grants = Stripe::Billing::CreditGrantService.new(@requestor)
      @meters = Stripe::Billing::MeterService.new(@requestor)
      @meter_events = Stripe::Billing::MeterEventService.new(@requestor)
      @meter_event_adjustments = Stripe::Billing::MeterEventAdjustmentService.new(@requestor)
    end
  end
end
