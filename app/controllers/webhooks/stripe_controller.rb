class Webhooks::StripeController < ApplicationController
  # skip_before_action :verify_authenticity_token

  def process_payload
    # Get the event payload and signature
    payload = request.body.read
    sig_header = request.headers['Stripe-Signature']
    web_secret = ENV.fetch('STRIPE_WEBHOOK_SECRET', nil)
    # Attempt to verify the signature. If successful, we'll handle the event
    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, web_secret)
      ::Enterprise::Billing::HandleStripeEventService.new.perform(event: event)
      # If we fail to verify the signature, then something was wrong with the request
    rescue JSON::ParserError => e
      # Invalid payload
      head :bad_request
      return
    rescue Stripe::SignatureVerificationError
      # Invalid signature
      head :bad_request
      return
    end

    # We've successfully processed the event without blowing up
    head :ok
  end
end
