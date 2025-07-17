class Waha::CallbackController < ApplicationController
  skip_before_action :authenticate_user!, :set_current_user
  skip_before_action :verify_authenticity_token

  def receive
    Rails.logger.info "WAHA webhook received: #{params.inspect}"
    
    phone_number = params[:phone_number]
    
    case params[:event]
    when 'message'
      process_message(phone_number)
    when 'state.change'
      process_state_change(phone_number)
    else
      Rails.logger.info "Unhandled WAHA event: #{params[:event]}"
    end

    render json: { status: 'ok' }
  end

  private

  def process_message(phone_number)
    return unless params[:payload].present?

    payload = params[:payload]
    
    return if payload[:fromMe] == true

    Waha::IncomingMessageService.new(
      params: {
        receiver: phone_number,
        sender: extract_phone_number(payload[:from]),
        sender_name: payload[:notifyName] || extract_phone_number(payload[:from]),
        message: extract_message_content(payload),
        message_id: payload[:id]
      }
    ).perform
  end

  def process_state_change(phone_number)
    # Rails.logger.info "WAHA state change for #{phone_number}: #{params[:payload]}"
  end

  def extract_phone_number(chat_id)
    chat_id.to_s.gsub(/@c\.us$/, '')
  end

  def extract_message_content(payload)
    payload[:body] || payload[:caption] || ''
  end
end