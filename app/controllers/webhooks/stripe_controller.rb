class Webhooks::StripeController < ActionController::API
  def process_payload
    # Get the event payload and signature
    payload = request.body.read
    sig_header = request.headers["Stripe-Signature"]

    # Attempt to verify the signature. If successful, we'll handle the event
    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"])
      ::Enterprise::Billing::HandleStripeEventService.new.call(event: event)
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
