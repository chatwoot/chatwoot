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
      if v2_billing_event?(event)
        handle_v2_event(event)
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

    # Use V2 webhook secret for V2 events, V1 secret for everything else
    if event_type&.start_with?('v2.')
      ENV.fetch('STRIPE_WEBHOOK_SECRET_V2', nil)
    else
      ENV.fetch('STRIPE_WEBHOOK_SECRET', nil)
    end
  end

  def v2_billing_event?(event)
    event.type.start_with?('v2.')
  end

  def handle_v2_event(event)
    account = find_account_for_v2_event(event)
    return unless account && account_v2_enabled?(account)

    service = ::Enterprise::Billing::V2::WebhookHandlerService.new(account: account)
    service.process(event)
  end

  def find_account_for_v2_event(event)
    related_object = event.related_object
    subscription_id = related_object.id

    customer_id = fetch_customer_id_from_subscription(subscription_id)
    if customer_id.present?
      account = Account.find_by("custom_attributes->>'stripe_customer_id' = ?", customer_id)
      return account if account
    end

    Rails.logger.warn "Could not find account for subscription #{subscription_id}"
    nil
  end

  def fetch_customer_id_from_subscription(subscription_id)
    # Step 1: Fetch subscription
    subscription = StripeV2Client.request(
      :get,
      "/v2/billing/pricing_plan_subscriptions/#{subscription_id}",
      {},
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
    return nil unless subscription&.billing_cadence

    # Step 2: Fetch billing cadence
    cadence = StripeV2Client.request(
      :get,
      "/v2/billing/cadences/#{subscription.billing_cadence}",
      {},
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
    # Step 3: Extract customer from payer
    cadence.payer&.customer
  end

  def account_v2_enabled?(_account)
    ENV.fetch('STRIPE_BILLING_V2_ENABLED', 'false') == 'true'
  end
end
