# frozen_string_literal: true

class Webhooks::WhapiController < ActionController::API
  def process_payload
    body = request.body.read
    request.body.rewind

    Rails.logger.info "[WHATSAPP LIGHT] Received webhook for inbox #{params[:inbox_id]}, event type: #{params[:event_type]}, method: #{request.method}"
    Rails.logger.debug "[WHATSAPP LIGHT] Webhook payload: #{body}"

    if request.put? || request.patch?
      Rails.logger.info "[WHATSAPP LIGHT] #{request.method} event received - inbox: #{params[:inbox_id]}, event_type: #{params[:event_type]}, body: #{body}"
      return head :ok
    end

    Webhooks::WhapiEventsJob.perform_later(params[:inbox_id], params[:event_type], body)

    head :ok
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP LIGHT] Webhook processing error: #{e.message}"
    head :ok # Return 200 to avoid webhook retries
  end
end
