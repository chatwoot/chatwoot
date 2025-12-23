# frozen_string_literal: true

require "stripe/resources/v2/core/event_notification"

module Stripe
  module Events
    class UnknownEventNotification < Stripe::V2::Core::EventNotification
      attr_reader :related_object

      def fetch_related_object
        return nil if @related_object.nil?

        resp = @client.raw_request(:get, related_object.url, opts: { stripe_context: context },
                                                             usage: ["fetch_related_object"])
        @client.deserialize(resp.http_body, api_mode: Util.get_api_mode(related_object.url))
      end
    end
  end
end
