# frozen_string_literal: true

class Webhooks::WhapiController < ActionController::API
  def process_payload
    Rails.logger.info "[WHATSAPP LIGHT] Received webhook for inbox #{params[:inbox_id]}, event type: #{params[:event_type]}"
    Rails.logger.debug "[WHATSAPP LIGHT] Webhook payload: #{request.body.read}"
    request.body.rewind

    Webhooks::WhapiEventsJob.perform_later(params[:inbox_id], params[:event_type], request.body.read)

    head :ok
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP LIGHT] Webhook processing error: #{e.message}"
    head :ok # Return 200 to avoid webhook retries
  end
end
