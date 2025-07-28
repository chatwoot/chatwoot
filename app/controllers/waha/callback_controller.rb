class Waha::CallbackController < ApplicationController
  skip_before_action :set_current_user

  def receive

    if params[:isGroup] == true
      Rails.logger.info "Callback from a group chat ignored. Phone: #{params[:phone_number]}"
      return head :ok
    end
  
    Rails.logger.info "=== WAHA WEBHOOK START ==="
    Rails.logger.info "WAHA webhook received: #{params.inspect}"
    Rails.logger.info "Request method: #{request.method}"
    Rails.logger.info "Request headers: #{request.headers.select { |k, _v| k.match(/content|accept|user-agent/i) }}"
    Rails.logger.info "Raw body: #{request.raw_post}" if request.raw_post.present?
    
    # DEBUGGING: Tampilkan semua data yang masuk dari WAHA
    Rails.logger.info "📋 WAHA CALLBACK DETAILS:"
    Rails.logger.info "  📞 Phone: #{params[:phone_number]}"
    Rails.logger.info "  🎯 Event: #{params[:event]}"
    Rails.logger.info "  📦 Legacy Payload: #{params[:payload]}" # Legacy format
    Rails.logger.info "  📊 Data: #{params[:data]}"
    Rails.logger.info "  🔑 Session: #{params[:session]}"
    Rails.logger.info "  📄 Full params keys: #{params.keys}"
    Rails.logger.info "  📥 Actual payload: #{params.except(:controller, :action, :phone_number)}"
    
    phone_number = params[:phone_number]
    
    # Handle GET request for webhook validation
    if request.get?
      Rails.logger.info "WAHA webhook GET request for validation"
      return head :ok
    end
    
    # Detect event type dari struktur payload berdasarkan 4 jenis callback WAHA aktual
    event_type = determine_event_type(params)
    Rails.logger.info "🎯 Detected event type: #{event_type}"
    
    # Process webhook events sesuai dengan 4 jenis callback yang benar
    case event_type
    when 'receipt'
      Rails.logger.info "📬 Processing WAHA receipt event - message status update"
      process_receipt(phone_number)
    when 'message'
      Rails.logger.info "📝 Processing WAHA regular message event"
      process_regular_message(phone_number)
    when 'initial_scan'
      Rails.logger.info "🎯 Processing WAHA initial scan validation - CRITICAL!"
      process_initial_scan(phone_number)
    else
      Rails.logger.warn "❓ Received an unhandled event type: #{event_type}. Payload: #{params.except(:controller, :action).inspect}"
    end

    Rails.logger.info "=== WAHA WEBHOOK END ==="
    head :ok
  rescue StandardError => e
    Rails.logger.error "WAHA webhook processing failed: #{e.message}"
    Rails.logger.error "Error backtrace: #{e.backtrace.first(5).join("\n")}"
    head :internal_server_error
  end

  private

  def determine_event_type(params)
    # Delegate to model helper method for consistency
    Channel::WhatsappUnofficial.determine_event_type(params)
  end

  def initial_scan_message?(params)
    # Delegate to model helper method for consistency
    Channel::WhatsappUnofficial.initial_scan_message?(params)
  end

  def process_receipt(phone_number)
    # Callback #1: Receipt untuk update message status (read/delivered)
    Rails.logger.info "📬 Processing receipt callback for #{phone_number}"
    
    receipt_data = params[:receipt]
    return unless receipt_data

    # # Dapatkan ID pesan dari WAHA, ini adalah source_id di database kita
    # message_source_id = receipt_data[:id]
    # message = Message.find_by(source_id: message_source_id)
    # return unless message

    # Dapatkan status baru ('delivered' atau 'read')
    new_status = receipt_data[:type]
    # Dapatkan timestamp event
    timestamp = Time.parse(receipt_data[:timestamp])

    receipt_data[:message_ids].each do |msg_id|
      message = Message.find_by(source_id: msg_id)
      next unless message

      # Jalankan job untuk setiap message_id
      Conversations::UpdateMessageStatusJob.perform_later(message.conversation_id, timestamp, new_status)
      Rails.logger.info "📬 Receipt for message #{msg_id} enqueued for status update to #{new_status}"
    end
  end

  def process_regular_message(phone_number)
    # Callback #2 dan #3: Regular message (ada pushname)  
    Rails.logger.info "📝 Processing regular message for #{phone_number}"
    
    return if params[:isFromMe] == true

    service_params = {
      # 'receiver' adalah nomor WAHA Anda, yang didapat dari URL
      receiver: phone_number,
      # 'sender' adalah nomor pelanggan, diekstrak dari field 'from'
      sender: Channel::WhatsappUnofficial.extract_phone_number(params[:from]), #
      # 'sender_name' adalah nama kontak di WhatsApp
      sender_name: params[:pushname],
      # 'message' adalah isi pesan
      message: extract_message_content(params), #
      # 'message_id' adalah ID unik dari WAHA yang akan menjadi source_id
      message_id: params.dig(:message, :id) || params[:id]
    }

    Waha::IncomingMessageService.new(params: service_params).perform
    
    Rails.logger.info "📝 Regular message processed successfully"
  end

  # ✅ UBAH: Sederhanakan method ini
  def process_initial_scan(phone_number)
    channel = Channel::WhatsappUnofficial.find_by(phone_number: phone_number)
    return unless channel

    # ⛔ HAPUS: Tidak perlu lagi set current_callback
    # channel.current_callback = callback_params

    callback_params = params.except(:phone_number, :controller, :action)
    
    # Panggil method model. Model akan menangani validasi DAN caching secara internal.
    result = channel.process_waha_callback_response(callback_params)
    Rails.logger.info "🔍 Callback processing result: #{result}"

    # Logika broadcast tetap sama, karena sudah benar
    case result[:action]
    when 'validate_success'
      Rails.logger.info "✅ Initial scan validation successful - session ready!"
      session_data = result[:data]
      broadcast_phone_validation_success(channel, session_data[:session_id])
      notify_session_ready(channel)
      
    when 'validate_failure'
      Rails.logger.error "❌ Initial scan validation failed - session already logged out"
      failure_data = result[:data]
      broadcast_session_mismatch(channel, failure_data[:connected_phone])
      
    else
      Rails.logger.info "📋 No specific action needed for callback type: #{result[:type]}"
    end
  end

  def process_message(phone_number)
    # Gunakan filter response dari model untuk menentukan action yang tepat
    channel = Channel::WhatsappUnofficial.find_by(phone_number: phone_number)
    return unless channel
    
    callback_params = params.except(:phone_number, :controller, :action)
    result = channel.process_waha_callback_response(callback_params)
    
    Rails.logger.info "� Message processing result: #{result}"
    
    case result[:action]
    when 'ignore'
      Rails.logger.info "� Ignoring receipt callback"
    when 'process_normally'
      Rails.logger.info "📝 Processing regular message normally"
      # TODO: Add actual message processing logic here
      # This is where you would integrate with Chatwoot's message handling system
    else
      Rails.logger.info "📨 Unknown message action: #{result[:action]}"
    end
  end

  def process_state_change(phone_number)
    # WAHA mengirim payload langsung di root level
    state_data = params.except(:phone_number, :controller, :action)
    
    Rails.logger.info "WAHA state change for #{phone_number}: #{state_data}"
    
    return if state_data.blank?
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

  def process_qr_code(phone_number)
    # WAHA mengirim payload langsung di root level
    qr_payload = params.except(:phone_number, :controller, :action)
    
    Rails.logger.info "QR Code event for #{phone_number}: #{qr_payload}"
    
    return if qr_payload.blank?
    
    qr_data = qr_payload[:qr]
    return unless qr_data
    
    channel = Channel::WhatsappUnofficial.find_by(phone_number: phone_number)
    return unless channel
    
    # Broadcast QR code to frontend for real-time display
    broadcast_qr_code(channel, qr_data)
  end

  def broadcast_session_status_change(channel, status)
    # Broadcast ke frontend menggunakan ActionCable untuk real-time updates
    Rails.logger.info "📻 Broadcasting session status change for #{channel.phone_number}: #{status}"
    
    # Use Chatwoot's pubsub system for consistent broadcasting
    inbox = channel.inbox
    account = inbox.account
    pubsub_token = "#{account.id}_inbox_#{inbox.id}"
    
    # Broadcast using Chatwoot's existing system
    ActionCable.server.broadcast(pubsub_token, {
      event: 'whatsapp_status_changed',
      type: 'session_status_changed', 
      status: status,
      phone_number: channel.phone_number,
      connected: status == 'logged_in',
      inbox_id: inbox.id,
      channel_id: channel.id
    })
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
    Rails.logger.info "🚀 WhatsApp session ready for #{channel.phone_number}"
    
    # Update channel status untuk memastikan konsistensi
    Rails.logger.info "📝 Updating channel status to active"
    
    # Broadcast final ready status ke frontend
    inbox = channel.inbox
    return unless inbox
    
    account = inbox.account
    pubsub_token = "#{account.id}_inbox_#{inbox.id}"
    
    ActionCable.server.broadcast(pubsub_token, {
      event: 'whatsapp_status_changed',
      type: 'session_ready',
      status: 'logged_in',
      phone_number: channel.phone_number,
      connected: true,
      message: 'WhatsApp session is ready for messaging!',
      inbox_id: inbox.id,
      channel_id: channel.id,
      timestamp: Time.current.iso8601
    })
    
    Rails.logger.info "📻 Session ready notification broadcasted"
    
    # Optional: Kirim email/notifikasi ke admin jika diperlukan
    # AdminNotificationMailer.whatsapp_session_ready(channel).deliver_later
  end

  def validate_connected_phone_number(channel, payload)
    # Extract phone number langsung dari payload callback
    connected_phone = Channel::WhatsappUnofficial.extract_connected_phone_number(payload)
    
    # Use model method for validation
    if channel.validate_phone_number_consistency(connected_phone)
      Rails.logger.info "Phone numbers match for #{channel.phone_number}"
      true
    else
      Rails.logger.error "SESSION PHONE MISMATCH!"
      Rails.logger.error "  Session: #{payload[:sessionID]}"
      false
    end
  end

  # Method ini sudah tidak diperlukan karena phone number didapat dari callback payload
  # def fetch_connected_phone_from_waha(api_key)
  #   Phone number sudah tersedia dari callback payload (from field)
  # end

  def extract_connected_phone_number(payload)
    # Delegate to model method for consistency
    Channel::WhatsappUnofficial.extract_connected_phone_number(payload)
  end

  def validate_self_message_phone(registered_phone, payload)
    # Ambil nomor dari message pertama device sendiri
    actual_phone = Channel::WhatsappUnofficial.extract_phone_number(payload[:from])
    session_id = payload[:sessionID]
    
    # Use model method for validation
    channel = Channel::WhatsappUnofficial.find_by(phone_number: registered_phone)
    return false unless channel
    
    Rails.logger.info 'SELF-MESSAGE VALIDATION:'
    Rails.logger.info "  Expected device: #{registered_phone}"
    Rails.logger.info "  Actual connected: #{actual_phone}"
    Rails.logger.info "  Session ID: #{session_id}"
    
    if channel.validate_phone_number_consistency(actual_phone)
      Rails.logger.info 'Phone validation SUCCESS via self-message!'
      
      # Use model method for success handling
      channel.handle_phone_validation_success(session_id)
      broadcast_phone_validation_success(channel, session_id)
      
      true
    else
      Rails.logger.error 'PHONE VALIDATION FAILED via self-message!'
      
      # Use model method for failure handling
      channel.handle_phone_validation_failure(actual_phone, session_id)
      handle_phone_validation_failure(registered_phone, actual_phone, session_id)
      
      false
    end
  end

  def broadcast_phone_validation_success(channel, session_id)
    Rails.logger.info "📻 Broadcasting phone validation success for #{channel.phone_number}"
    
    # Use Chatwoot's pubsub system untuk konsistensi
    inbox = channel.inbox
    account = inbox.account
    pubsub_token = "#{account.id}_inbox_#{inbox.id}"
    
    # Broadcast menggunakan sistem Chatwoot yang sudah ada
    ActionCable.server.broadcast(pubsub_token, {
      event: 'whatsapp_status_changed',
      type: 'phone_validation_success',
      status: 'logged_in',
      phone_number: channel.phone_number,
      session_id: session_id,
      connected: true,
      phone_validated: true,
      message: 'Phone number validation successful! WhatsApp is now connected.',
      inbox_id: inbox.id,
      channel_id: channel.id,
      timestamp: Time.current.iso8601,
      next_action: 'redirect_to_inbox' # Hint untuk frontend
    })
    
    Rails.logger.info "✅ Phone validation success broadcasted with redirect hint"
  end

  def handle_phone_validation_failure(registered_phone, actual_phone, session_id)
    Rails.logger.error "🚨 CRITICAL: Phone validation failed on first message!"
    
    channel = Channel::WhatsappUnofficial.find_by(phone_number: registered_phone)
    if channel
      Rails.logger.error "🔒 Disconnecting session due to phone validation failure"
      Rails.logger.error "  Channel ID: #{channel.id}"
      Rails.logger.error "  Session ID: #{session_id}"
      
      # Update cache dengan status mismatch
      channel.update_session_status_cache('mismatch')
      
      # Broadcast mismatch ke frontend
      broadcast_session_mismatch(channel, actual_phone)
      
      # Disconnect dari WAHA
      begin
        disconnect_waha_session(channel.token) if channel.token.present?
      rescue StandardError => e
        Rails.logger.error "Failed to disconnect WAHA session: #{e.message}"
      end
    end
  end

  def validate_message_sender(registered_phone, sender_phone, payload)
    return true if sender_phone.blank? # Skip validation jika tidak bisa extract sender
    
    # Use model method for validation
    channel = Channel::WhatsappUnofficial.find_by(phone_number: registered_phone)
    return true unless channel # Skip validation if channel not found
    
    Rails.logger.info 'MESSAGE VALIDATION:'
    Rails.logger.info "  Registered device: #{registered_phone}"
    Rails.logger.info "  Message sender: #{sender_phone}"
    Rails.logger.info "  Session ID: #{payload[:sessionID]}"
    
    if channel.validate_phone_number_consistency(sender_phone)
      Rails.logger.info 'Message sender matches registered device'
      true
    else
      Rails.logger.error 'MESSAGE PHONE MISMATCH!'
      Rails.logger.error "  Session: #{payload[:sessionID]}"
      
      # Handle message phone mismatch
      handle_message_phone_mismatch(registered_phone, sender_phone, payload)
      
      false
    end
  end

  def handle_message_phone_mismatch(registered_phone, sender_phone, payload)
    Rails.logger.error "🚨 CRITICAL: Phone number mismatch in active session!"
    
    # Find channel dan disconnect jika perlu
    channel = Channel::WhatsappUnofficial.find_by(phone_number: registered_phone)
    if channel
      disconnect_session_due_to_mismatch(channel, payload)
    end
  end

  def normalize_phone_number(phone)
    # Delegate to model method for consistency
    channel = Channel::WhatsappUnofficial.new
    channel.normalize_phone_number(phone)
  end

  def disconnect_session_due_to_mismatch(channel, payload)
    connected_phone = Channel::WhatsappUnofficial.extract_connected_phone_number(payload)
    
    Rails.logger.error "Disconnecting session for #{channel.phone_number} due to phone mismatch"
    Rails.logger.error "Connected phone: #{connected_phone}"
    
    # Use model method for handling phone validation failure
    channel.handle_phone_validation_failure(connected_phone, payload[:sessionID])
    
    # Broadcast mismatch status
    broadcast_session_mismatch(channel, connected_phone)
    
    # Try to logout session using model method
    channel.disconnect_waha_session if channel.token.present?
  end

  def disconnect_waha_session(api_key)
    # Create temporary channel instance to use model method
    channel = Channel::WhatsappUnofficial.new
    channel.token = api_key
    channel.disconnect_waha_session
  end

  def broadcast_session_mismatch(channel, connected_phone)
    Rails.logger.info "Broadcasting session mismatch for #{channel.phone_number}"
    
    # Check if mismatch was already broadcasted recently to prevent spam
    mismatch_cache_key = "mismatch_broadcast_#{channel.phone_number}"
    return if Rails.cache.exist?(mismatch_cache_key)
    
    # Set cache to prevent duplicate broadcasts for 30 seconds
    Rails.cache.write(mismatch_cache_key, true, expires_in: 30.seconds)
    
    # Broadcast ke frontend untuk memberitahu user tentang mismatch
    inbox = channel.inbox
    return unless inbox

    account = inbox.account
    pubsub_token = "#{account.id}_inbox_#{inbox.id}"

    ActionCable.server.broadcast(pubsub_token, {
      event: 'whatsapp_status_changed',
      type: 'session_mismatch',
      status: 'mismatch',
      expected_phone: channel.phone_number,
      connected_phone: connected_phone,
      message: 'WhatsApp number mismatch detected. Please scan QR code with the correct phone number.',
      inbox_id: inbox.id,
      channel_id: channel.id
    })
  end

  def extract_phone_number(chat_id)
    # Delegate to model method for consistency
    Channel::WhatsappUnofficial.extract_phone_number(chat_id)
  end

  def extract_message_content(payload)
    payload.dig(:message, :text) || payload[:body] || payload[:caption] || ''
  end
end