class Waha::CallbackController < ApplicationController
  skip_before_action :set_current_user

  def receive
    Rails.logger.info "=== WAHA WEBHOOK START ==="
    Rails.logger.info "WAHA webhook received: #{params.inspect}"
    Rails.logger.info "Request method: #{request.method}"
    Rails.logger.info "Request headers: #{request.headers.select { |k, _v| k.match(/content|accept|user-agent/i) }}"
    Rails.logger.info "Raw body: #{request.raw_post}" if request.raw_post.present?
    
    # DEBUGGING: Tampilkan semua data yang masuk dari WAHA
    Rails.logger.info "📋 WAHA CALLBACK DETAILS:"
    Rails.logger.info "  📞 Phone: #{params[:phone_number]}"
    Rails.logger.info "  🎯 Event: #{params[:event]}"
    Rails.logger.info "  📦 Payload: #{params[:payload]}"
    Rails.logger.info "  📊 Data: #{params[:data]}"
    Rails.logger.info "  🔑 Session: #{params[:session]}"
    Rails.logger.info "  📄 Full params keys: #{params.keys}"
    
    phone_number = params[:phone_number]
    
    # Handle GET request for webhook validation
    if request.get?
      Rails.logger.info "WAHA webhook GET request for validation"
      return head :ok
    end
    
    # Process webhook events sesuai dengan alur callback yang benar
    case params[:event]
    when 'message'
      Rails.logger.info "Processing WAHA message event"
      process_message(phone_number)
    when 'state.change'
      Rails.logger.info "Processing WAHA state change event"
      process_state_change(phone_number)
    when 'session.status'
      Rails.logger.info "Processing WAHA session status event - PALING PENTING!"
      process_session_status(phone_number)
    when 'qr_code'
      Rails.logger.info "Processing WAHA QR code event"
      process_qr_code(phone_number)
    else
      Rails.logger.info "❓ Unhandled WAHA event: #{params[:event]}"
      Rails.logger.info "❓ Full unhandled payload: #{params.to_json}"
    end

    Rails.logger.info "=== WAHA WEBHOOK END ==="
    head :ok
  rescue StandardError => e
    Rails.logger.error "WAHA webhook processing failed: #{e.message}"
    Rails.logger.error "Error backtrace: #{e.backtrace.first(5).join("\n")}"
    head :internal_server_error
  end

  private

  def process_message(phone_number)
    return if params[:payload].blank?

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
    Rails.logger.info "WAHA state change for #{phone_number}: #{params[:payload]}"
    
    return if params[:payload].blank?
    
    state_data = params[:payload]
    return unless state_data[:state] == 'disconnected'
    
    # Reset session when disconnected
    channel = Channel::WhatsappUnofficial.find_by(phone_number: phone_number)
    if channel
      channel.update!(token: nil)
      Rails.logger.info "Token cleared for disconnected session: #{phone_number}"
      
      # Broadcast status change to frontend
      broadcast_session_status_change(channel, 'disconnected')
    end
  end

  # INI ADALAH BAGIAN TERPENTING SESUAI ALUR YANG BENAR!
  def process_session_status(phone_number)
    Rails.logger.info "WAHA session status for #{phone_number}: #{params[:payload]}"
    
    return if params[:payload].blank?
    
    payload = params[:payload]
    status = payload[:status]
    channel = Channel::WhatsappUnofficial.find_by(phone_number: phone_number)
    
    return unless channel && status
    
    Rails.logger.info "Processing session status change for #{phone_number}: #{status}"
    
    case status.to_s.downcase
    when 'not_logged_in', 'disconnected', 'logged_out', 'not_authenticated'
      Rails.logger.info "Session disconnected for #{phone_number}, clearing token"
      channel.update!(token: nil)
      broadcast_session_status_change(channel, 'not_logged_in')
    when 'logged_in', 'working', 'authenticated', 'ready'
      # INI ADALAH MOMEN PENTING! Sesi sudah siap digunakan
      Rails.logger.info "🎉 Session READY for #{phone_number}! Status: #{status}"
      broadcast_session_status_change(channel, 'logged_in')
      
      # Optional: Kirim notifikasi ke admin bahwa sesi sudah siap
      notify_session_ready(channel)
    when 'starting', 'initializing', 'qr_code'
      Rails.logger.info "Session initializing for #{phone_number}: #{status}"
      broadcast_session_status_change(channel, 'initializing')
    else
      Rails.logger.info "Unknown session status for #{phone_number}: #{status}"
      broadcast_session_status_change(channel, status.to_s)
    end
  end

  def process_qr_code(phone_number)
    Rails.logger.info "QR Code event for #{phone_number}: #{params[:payload]}"
    
    return if params[:payload].blank?
    
    qr_data = params[:payload][:qr]
    return unless qr_data
    
    channel = Channel::WhatsappUnofficial.find_by(phone_number: phone_number)
    return unless channel
    
    # Broadcast QR code to frontend for real-time display
    broadcast_qr_code(channel, qr_data)
  end

  def broadcast_session_status_change(channel, status)
    # Broadcast ke frontend menggunakan ActionCable untuk real-time updates
    # Implementasi tergantung pada setup ActionCable yang ada
    Rails.logger.info "Broadcasting session status change for #{channel.phone_number}: #{status}"
    
    # Contoh broadcast jika menggunakan ActionCable
    # ActionCable.server.broadcast("whatsapp_channel_#{channel.id}", {
    #   type: 'session_status_changed',
    #   status: status,
    #   phone_number: channel.phone_number
    # })
  end

  def broadcast_qr_code(channel, qr_data)
    Rails.logger.info "Broadcasting QR code for #{channel.phone_number}"
    
    # Broadcast QR code ke frontend untuk ditampilkan
    # ActionCable.server.broadcast("whatsapp_channel_#{channel.id}", {
    #   type: 'qr_code',
    #   qr_code: qr_data,
    #   phone_number: channel.phone_number
    # })
  end

  def notify_session_ready(channel)
    Rails.logger.info "Session ready notification for #{channel.phone_number}"
    
    # Optional: Kirim email/notifikasi ke admin
    # atau update database dengan status
    # AdminNotificationMailer.whatsapp_session_ready(channel).deliver_later
  end

  def extract_phone_number(chat_id)
    chat_id.to_s.gsub(/@c\.us$/, '')
  end

  def extract_message_content(payload)
    payload[:body] || payload[:caption] || ''
  end
end