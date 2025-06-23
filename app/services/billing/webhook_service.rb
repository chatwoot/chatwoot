# frozen_string_literal: true

module Billing
  # Generic webhook service that delegates to the configured payment provider
  # This service provides an additional abstraction layer for webhook processing
  class WebhookService
    def initialize
      @provider = ProviderFactory.get_provider
    end

    # Verifies webhook signature using the configured provider
    def verify_signature(payload, signature, secret)
      return false if signature.blank? || secret.blank?

      @provider.verify_webhook_signature(payload, signature, secret)
    rescue StandardError => e
      Rails.logger.error "Webhook signature verification failed: #{e.message}"
      false
    end

    # Processes webhook event using the configured provider
    def process_event(event_data)
      Rails.logger.info '---[WEBHOOK SERVICE - PROCESS EVENT]---'
      Rails.logger.info "Provider: #{@provider.provider_name}"
      Rails.logger.info "Event Type: #{event_data['type']}"
      Rails.logger.info "Processing webhook via #{@provider.provider_name} provider: #{event_data['type']}"

      result = @provider.handle_webhook(event_data)

      if result[:success]
        Rails.logger.info "Webhook processed successfully: #{result[:message]}"
      else
        Rails.logger.error "Webhook processing failed: #{result[:error]}"
      end

      result
    rescue StandardError => e
      Rails.logger.error "Error in WebhookService: #{e.message}"
      {
        success: false,
        error: "Webhook processing failed: #{e.message}",
        provider: @provider.provider_name
      }
    end

    # Returns the current provider name
    def provider_name
      @provider.provider_name
    end

    # Gets the webhook secret for the current provider
    def webhook_secret
      case @provider.provider_name
      when 'stripe'
        ENV.fetch('STRIPE_WEBHOOK_SECRET', nil)
      when 'paypal'
        ENV.fetch('PAYPAL_WEBHOOK_SECRET', nil)
      when 'paddle'
        ENV.fetch('PADDLE_WEBHOOK_SECRET', nil)
      else
        Rails.logger.warn "No webhook secret configured for provider: #{@provider.provider_name}"
        nil
      end
    end

    # Validates that the webhook is properly configured
    def configured?
      webhook_secret.present?
    end
  end
end