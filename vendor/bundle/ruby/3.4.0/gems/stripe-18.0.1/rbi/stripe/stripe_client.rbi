# frozen_string_literal: true
# typed: true

module Stripe
  class StripeClient
    sig do
      params(
        payload: String,
        sig_header: String,
        secret: String,
        tolerance: T.nilable(Integer)
      )
        .returns(::Stripe::V2::Core::EventNotification)
    end
    def parse_event_notification(payload, sig_header, secret, tolerance:); end
  end
end
