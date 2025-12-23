# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TerminalService < StripeService
    attr_reader :configurations, :connection_tokens, :locations, :onboarding_links, :readers

    def initialize(requestor)
      super
      @configurations = Stripe::Terminal::ConfigurationService.new(@requestor)
      @connection_tokens = Stripe::Terminal::ConnectionTokenService.new(@requestor)
      @locations = Stripe::Terminal::LocationService.new(@requestor)
      @onboarding_links = Stripe::Terminal::OnboardingLinkService.new(@requestor)
      @readers = Stripe::Terminal::ReaderService.new(@requestor)
    end
  end
end
