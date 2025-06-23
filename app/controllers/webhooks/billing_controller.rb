# frozen_string_literal: true

class Webhooks::BillingController < ActionController::Base
  # This controller handles webhooks and doesn't need standard Rails authentication
  protect_from_forgery with: :null_session

  # POST /webhooks/billing/process_event
  def process_event
    webhook_service = Billing::WebhookService.new

    unless webhook_service.configured?
      Rails.logger.error 'Webhook secret not configured'
      render json: { error: 'Webhook not configured' }, status: :internal_server_error
      return
    end

    payload = request.body.read
    signature = extract_signature_header(webhook_service.provider_name)

    # Log incoming webhook for debugging
    Rails.logger.info '---[BILLING WEBHOOK RECEIVED]---'
    Rails.logger.info "Payload: #{payload}"
    Rails.logger.info "Signature: #{signature}"

    begin
      # Verify webhook signature using the webhook service
      if webhook_service.verify_signature(payload, signature, webhook_service.webhook_secret)
        # Parse the event data
        event_data = JSON.parse(payload)

        # Process the event using the webhook service
        result = webhook_service.process_event(event_data)

        if result[:success]
          render json: { received: true, message: result[:message] }, status: :ok
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      else
        Rails.logger.error "#{webhook_service.provider_name.capitalize} webhook signature verification failed"
        render json: { error: 'Invalid signature' }, status: :bad_request
      end

    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON in webhook: #{e.message}"
      render json: { error: 'Invalid JSON' }, status: :bad_request
    rescue StandardError => e
      Rails.logger.error "Error processing webhook: #{e.message}"
      render json: { error: 'Webhook processing failed' }, status: :internal_server_error
    end
  end

  # GET /webhooks/billing/health
  def health
    webhook_service = Billing::WebhookService.new
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      provider: webhook_service.provider_name,
      webhook_endpoint: 'active',
      configured: webhook_service.configured?
    }
  end

  private

  def extract_signature_header(provider_name = nil)
    # Different providers use different header names
    case provider_name
    when 'stripe'
      request.env['HTTP_STRIPE_SIGNATURE']
    when 'paypal'
      request.env['HTTP_PAYPAL_TRANSMISSION_SIG']
    when 'paddle'
      request.env['HTTP_PADDLE_SIGNATURE']
    else
      # Fallback to common header names
      request.env['HTTP_STRIPE_SIGNATURE'] || # Stripe (default)
        request.env['HTTP_X_WEBHOOK_SIGNATURE'] || # Generic
        request.env['HTTP_SIGNATURE'] # Other providers
    end
  end
end