# frozen_string_literal: true

class Webhooks::WhapiGroupsController < ActionController::API
  def process_payload
    body = request.body.read
    request.body.rewind

    Rails.logger.info "[WHATSAPP GROUPS] Received webhook for event type: #{params[:event_type]}"
    Rails.logger.debug { "[WHATSAPP GROUPS] Webhook payload: #{body}" }

    Webhooks::WhapiGroupEventsJob.perform_later(params[:event_type], body)

    head :ok
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP GROUPS] Webhook processing error: #{e.message}"
    head :ok # Return 200 to avoid webhook retries
  end
end
