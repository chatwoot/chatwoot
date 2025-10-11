class Enterprise::Webhooks::StripeController < ActionController::API
  def process_payload
    # Get the event payload and signature
    payload = request.body.read
    sig_header = request.headers['Stripe-Signature']

    # Attempt to verify the signature. If successful, we'll handle the event
    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, ENV.fetch('STRIPE_WEBHOOK_SECRET', nil))

      # Check if this is a V2 billing event
      if v2_billing_event?(event)
        handle_v2_event(event)
      else
        # Handle V1 events with existing service
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

  def v2_billing_event?(event)
    %w[
      billing.credit_grant.created
      billing.credit_grant.expired
    ].include?(event.type)
  end

  def handle_v2_event(event)
    customer_id = extract_customer_id(event)
    return if customer_id.blank?

    account = Account.find_by("custom_attributes->>'stripe_customer_id' = ?", customer_id)
    return unless account&.custom_attributes&.[]('stripe_billing_version').to_i == 2

    service = ::Enterprise::Billing::V2::WebhookHandlerService.new(account: account)
    service.process(event)
  end

  def extract_customer_id(event)
    data = event.data.object

    # Credit grants have customer field
    if data.respond_to?(:customer)
      data.customer
    elsif data.respond_to?(:[])
      data['customer']
    end
  end
end
