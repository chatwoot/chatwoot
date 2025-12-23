# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module V2
    class CoreService < StripeService
      attr_reader :events, :event_destinations

      def initialize(requestor)
        super
        @events = Stripe::V2::Core::EventService.new(@requestor)
        @event_destinations = Stripe::V2::Core::EventDestinationService.new(@requestor)
      end
    end
  end
end
