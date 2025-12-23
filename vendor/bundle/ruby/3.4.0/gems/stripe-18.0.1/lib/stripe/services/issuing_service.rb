# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class IssuingService < StripeService
    attr_reader :authorizations, :cards, :cardholders, :disputes, :personalization_designs, :physical_bundles, :tokens, :transactions

    def initialize(requestor)
      super
      @authorizations = Stripe::Issuing::AuthorizationService.new(@requestor)
      @cards = Stripe::Issuing::CardService.new(@requestor)
      @cardholders = Stripe::Issuing::CardholderService.new(@requestor)
      @disputes = Stripe::Issuing::DisputeService.new(@requestor)
      @personalization_designs = Stripe::Issuing::PersonalizationDesignService.new(@requestor)
      @physical_bundles = Stripe::Issuing::PhysicalBundleService.new(@requestor)
      @tokens = Stripe::Issuing::TokenService.new(@requestor)
      @transactions = Stripe::Issuing::TransactionService.new(@requestor)
    end
  end
end
