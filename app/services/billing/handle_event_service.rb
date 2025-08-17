# frozen_string_literal: true

module Billing
  # Service to handle incoming webhook events from payment provider
  # Delegates to the configured provider for processing
  class HandleEventService
    def initialize(event_data)
      @event_data = event_data
      @provider = ProviderFactory.get_provider
    rescue StandardError => e
      Rails.logger.error "Error initializing provider: #{e.message}"
      @provider_error = e
    end

    def perform
      # Return error immediately if provider initialization failed
      if @provider_error
        return {
          success: false,
          error: "Webhook processing failed: #{@provider_error.message}",
          event_type: @event_data['type']
        }
      end

      Rails.logger.info "Processing webhook event: #{@event_data['type']} via #{@provider.provider_name} provider"

      # Delegate to the provider's webhook handler
      result = @provider.handle_webhook(@event_data)

      if result[:success]
        Rails.logger.info "Successfully processed webhook: #{result[:message]}"
      else
        Rails.logger.error "Failed to process webhook: #{result[:error]}"
      end

      result
    rescue StandardError => e
      Rails.logger.error "Error in HandleEventService: #{e.message}"
      {
        success: false,
        error: "Webhook processing failed: #{e.message}",
        event_type: @event_data['type']
      }
    end
  end
end