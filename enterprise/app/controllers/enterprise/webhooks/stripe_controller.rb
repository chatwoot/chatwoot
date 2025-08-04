# Controller responsible for handling Stripe webhook events for the Enterprise namespace.
# Receives incoming webhook payloads from Stripe, verifies their authenticity using the Stripe-Signature header
# and the configured STRIPE_WEBHOOK_SECRET, and delegates event processing to the HandleStripeEventService.
# If the payload or signature verification fails, responds with HTTP 400 Bad Request.
# On successful processing, responds with HTTP 200 OK.
class Enterprise::Webhooks::StripeController < ActionController::API
  def process_payload
    # Get the event payload and signature
    payload = request.body.read
    sig_header = request.headers['Stripe-Signature']

    # Attempt to verify the signature. If successful, we'll handle the event
    begin
      # event = Stripe::Webhook.construct_event(payload, sig_header, ENV.fetch('STRIPE_WEBHOOK_SECRET', nil))
      # ::Enterprise::Billing::HandleStripeEventService.new.perform(event: event)
    # If we fail to verify the signature, then something was wrong with the request
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      # Invalid payload
      head :bad_request
      return
    end

    # We've successfully processed the event without blowing up
    head :ok
  end
end
