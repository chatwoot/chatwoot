class Api::V1::Waha::WebhooksController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user
  # skip_before_action :verify_authenticity_token

  def callback
    phone_number = params[:phone_number]

    Rails.logger.info "WAHA webhook received for phone #{phone_number}: #{params.inspect}"

    # Handle GET request for webhook validation
    return head :ok if request.get? || request.head?

    # Process webhook events
    process_waha_webhook(phone_number, params)

    head :ok
  rescue StandardError => e
    Rails.logger.error "WAHA webhook processing failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    head :internal_server_error
  end

  private

  def process_waha_webhook(phone_number, webhook_params)
    case webhook_params[:event] || webhook_params['event']
    when 'session.status'
      handle_session_status(phone_number, webhook_params)
    when 'message'
      handle_incoming_message(phone_number, webhook_params)
    when 'state.change'
      handle_state_change(phone_number, webhook_params)
    when 'qr'
      Rails.logger.info "QR code update for phone #{phone_number}"
    else
      Rails.logger.info "Unknown WAHA webhook event: #{webhook_params[:event] || webhook_params['event']}"
    end
  end

  def handle_session_status(phone_number, webhook_params)
    Rails.logger.info "WAHA session status for #{phone_number}: #{webhook_params[:data] || webhook_params['data']}"

    status = webhook_params.dig(:data, :status) || webhook_params.dig('data', 'status')
    channel = Channel::WhatsappUnofficial.find_by(phone_number: phone_number)

    return unless channel && status

    case status.to_s.downcase
    when 'not_logged_in', 'disconnected', 'logged_out', 'not_authenticated'
      Rails.logger.info "Session disconnected for #{phone_number}, clearing token"
      channel.update!(token: nil)
    when 'logged_in', 'authenticated'
      Rails.logger.info "Session connected for #{phone_number}"
    end
  end

  def handle_incoming_message(phone_number, webhook_params)
    # Menggunakan service pattern seperti Fonnte
    Waha::IncomingMessageService.new(
      params: build_message_params(phone_number, webhook_params)
    ).perform
  rescue StandardError => e
    Rails.logger.error "Failed to process incoming message for #{phone_number}: #{e.message}"
  end

  def handle_state_change(phone_number, webhook_params)
    Rails.logger.info "WAHA state change for #{phone_number}"

    state_data = webhook_params[:payload] || webhook_params[:data] || webhook_params['payload'] || webhook_params['data']
    return unless state_data

    return unless state_data[:state] == 'disconnected' || state_data['state'] == 'disconnected'

    channel = Channel::WhatsappUnofficial.find_by(phone_number: phone_number)
    channel&.update!(token: nil)
  end

  def build_message_params(phone_number, webhook_params)
    payload = webhook_params[:payload] || webhook_params[:data] || webhook_params['payload'] || webhook_params['data']
    return {} unless payload
    return {} if payload[:fromMe] == true || payload['fromMe'] == true

    {
      receiver: phone_number,
      sender: extract_phone_number(payload[:from] || payload['from']),
      sender_name: payload[:notifyName] || payload['notifyName'] || extract_phone_number(payload[:from] || payload['from']),
      message: extract_message_content(payload),
      message_id: payload[:id] || payload['id']
    }
  end

  def extract_phone_number(chat_id)
    chat_id.to_s.gsub(/@c\.us$/, '')
  end

  def extract_message_content(payload)
    payload[:body] || payload['body'] || payload[:caption] || payload['caption'] || ''
  end
end
