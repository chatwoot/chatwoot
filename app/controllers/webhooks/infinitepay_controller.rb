# frozen_string_literal: true

class Webhooks::InfinitepayController < ActionController::API
  def process_payload
    payload = params.to_unsafe_hash.except(:controller, :action)
    Integrations::Infinitepay::WebhookProcessorService.new(payload).perform
    head :ok
  rescue StandardError => e
    Rails.logger.error "[INFINITEPAY-WEBHOOK] Error: #{e.class}: #{e.message}"
    head :bad_request
  end
end
