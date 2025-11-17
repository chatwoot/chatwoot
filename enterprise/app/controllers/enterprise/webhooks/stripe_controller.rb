class Enterprise::Webhooks::StripeController < ActionController::API
  def process_payload
    # Get the event payload and signature
    payload = request.body.read
    sig_header = request.headers['Stripe-Signature']

    # Attempt to verify the signature. If successful, we'll handle the event
    begin
      # Determine which webhook secret to use based on event type
      webhook_secret = determine_webhook_secret(payload)

      event = Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)

      # Check if this is a V2 billing event
      if v2_billing_event?(event.type)
        ::Enterprise::Billing::V2::WebhookHandlerService.new.perform(event: event)
      else
        ::Enterprise::Billing::HandleStripeEventService.new.perform(event: event)
      end
    # If we fail to verify the signature, then something was wrong with the request
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      # Invalid payload
      head :bad_request
      return
    end

    # We've successfully processed the event without blowing up
    head :ok
  end

  private

  def determine_webhook_secret(payload)
    # Parse the payload to check event type without full verification
    parsed_payload = JSON.parse(payload)
    event_type = parsed_payload['type']

    if v2_billing_event?(event_type)
      ENV.fetch('STRIPE_WEBHOOK_SECRET_V2', nil)
    else
      ENV.fetch('STRIPE_WEBHOOK_SECRET', nil)
    end
  end

  def v2_billing_event?(event_type)
    Rails.logger.debug { "V2 billing event: #{event_type}" }
    event_type.start_with?('v2.') if event_type.present?
  end
end
