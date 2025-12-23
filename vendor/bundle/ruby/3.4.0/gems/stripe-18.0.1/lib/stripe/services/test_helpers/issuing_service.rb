# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    class IssuingService < StripeService
      attr_reader :authorizations, :cards, :personalization_designs, :transactions

      def initialize(requestor)
        super
        @authorizations = Stripe::TestHelpers::Issuing::AuthorizationService.new(@requestor)
        @cards = Stripe::TestHelpers::Issuing::CardService.new(@requestor)
        @personalization_designs = Stripe::TestHelpers::Issuing::PersonalizationDesignService
                                   .new(@requestor)
        @transactions = Stripe::TestHelpers::Issuing::TransactionService.new(@requestor)
      end
    end
  end
end
