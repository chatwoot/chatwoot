class Api::V1::Waha::WebhooksController < ApplicationController
  skip_before_action :authenticate, only: [:callback]
  skip_before_action :verify_authenticity_token

  def callback
    phone_number = params[:phone_number]
    payload = params.permit!.to_h

    Rails.logger.info "WAHA webhook received for phone #{phone_number}: #{payload}"

    # Process webhook based on event type
    case payload['event']
    when 'session.status'
      handle_session_status(phone_number, payload)
    when 'message'
      handle_incoming_message(phone_number, payload)
    else
      Rails.logger.info "Unknown WAHA webhook event: #{payload['event']}"
    end

    render json: { status: 'ok' }
  rescue StandardError => e
    Rails.logger.error "WAHA webhook processing failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: 'Internal server error' }, status: :internal_server_error
  end

  private

  def handle_session_status(phone_number, payload)
    # Rails.logger.info "Session status update for #{phone_number}: #{payload['data']}"
  end

  def handle_incoming_message(phone_number, payload)
    # Rails.logger.info "Incoming message for #{phone_number}: #{payload['data']}"
  end
end
