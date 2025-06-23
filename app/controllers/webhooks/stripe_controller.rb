# frozen_string_literal: true

class Webhooks::StripeController < ActionController::Base
  # This controller handles webhooks and doesn't need standard Rails authentication
  protect_from_forgery with: :null_session

  # POST /webhooks/stripe/process_event
  def process_event
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']

    begin
      # Verify webhook signature
      event = verify_webhook_signature(payload, sig_header)

      # Process the event
      service = Billing::HandleEventService.new(event)
      result = service.perform

      if result[:success]
        Rails.logger.info "Successfully processed Stripe webhook: #{event['type']}"
        render json: { received: true, message: result[:message] }, status: :ok
      else
        Rails.logger.error "Failed to process Stripe webhook: #{result[:error]}"
        render json: { error: result[:error] }, status: :unprocessable_entity
      end

    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Stripe webhook signature verification failed: #{e.message}"
      render json: { error: 'Invalid signature' }, status: :bad_request
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON in Stripe webhook: #{e.message}"
      render json: { error: 'Invalid JSON' }, status: :bad_request
    rescue StandardError => e
      Rails.logger.error "Error processing Stripe webhook: #{e.message}"
      render json: { error: 'Webhook processing failed' }, status: :internal_server_error
    end
  end

  # GET /webhooks/stripe/health
  def health
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      webhook_endpoint: 'active'
    }
  end

  private

  def verify_webhook_signature(payload, sig_header)
    endpoint_secret = ENV.fetch('STRIPE_WEBHOOK_SECRET', nil)

    if endpoint_secret.blank?
      Rails.logger.error 'STRIPE_WEBHOOK_SECRET not configured'
      raise StandardError, 'Webhook secret not configured'
    end

    # Verify the webhook signature and construct the event
    Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
  rescue Stripe::SignatureVerificationError => e
    Rails.logger.error "Stripe signature verification failed: #{e.message}"
    raise e
  end
end