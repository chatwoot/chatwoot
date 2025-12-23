# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    class TerminalService < StripeService
      attr_reader :readers

      def initialize(requestor)
        super
        @readers = Stripe::TestHelpers::Terminal::ReaderService.new(@requestor)
      end
    end
  end
end
