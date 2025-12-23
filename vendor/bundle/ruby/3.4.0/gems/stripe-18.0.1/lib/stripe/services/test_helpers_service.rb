# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TestHelpersService < StripeService
    attr_reader :confirmation_tokens, :customers, :issuing, :refunds, :terminal, :test_clocks, :treasury

    def initialize(requestor)
      super
      @confirmation_tokens = Stripe::TestHelpers::ConfirmationTokenService.new(@requestor)
      @customers = Stripe::TestHelpers::CustomerService.new(@requestor)
      @issuing = Stripe::TestHelpers::IssuingService.new(@requestor)
      @refunds = Stripe::TestHelpers::RefundService.new(@requestor)
      @terminal = Stripe::TestHelpers::TerminalService.new(@requestor)
      @test_clocks = Stripe::TestHelpers::TestClockService.new(@requestor)
      @treasury = Stripe::TestHelpers::TreasuryService.new(@requestor)
    end
  end
end
