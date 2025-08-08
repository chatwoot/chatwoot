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
    
    Rails.logger.info "📋 WAHA CALLBACK DETAILS:"
    Rails.logger.info "  📞 Phone: #{params[:phone_number]}"
    Rails.logger.info "  🎯 Event: #{params[:event]}"
    Rails.logger.info "  📦 Legacy Payload: #{params[:payload]}" # Legacy format
    Rails.logger.info "  📊 Data: #{params[:data]}"
    Rails.logger.info "  🔑 Session: #{params[:session]}"
    Rails.logger.info "  📄 Full params keys: #{params.keys}"
    Rails.logger.info "  📥 Actual payload: #{params.except(:controller, :action, :phone_number)}"
    
    phone_number = params[:phone_number]
    
    if request.get?
      Rails.logger.info "WAHA webhook GET request for validation"
      return head :ok
    end
    
    event_type = determine_event_type(params)
    Rails.logger.info "🎯 Detected event type: #{event_type}"
    
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
    Channel::WhatsappUnofficial.determine_event_type(params)
  end

  def initial_scan_message?(params)
    Channel::WhatsappUnofficial.initial_scan_message?(params)
  end

  def process_receipt(phone_number)
    Rails.logger.info "📬 Processing receipt callback for #{phone_number}"
    
    receipt_data = params[:receipt]
    return unless receipt_data

    new_status = receipt_data[:type]
    timestamp = Time.parse(receipt_data[:timestamp])

    receipt_data[:message_ids].each do |msg_id|
      message = Message.find_by(source_id: msg_id)
      next unless message

      Conversations::UpdateMessageStatusJob.perform_later(message.conversation_id, timestamp, new_status)
      Rails.logger.info "📬 Receipt for message #{msg_id} enqueued for status update to #{new_status}"
    end
  end

  def process_regular_message(phone_number)
    Rails.logger.info "📝 Processing regular message for #{phone_number}"
    
    return if params[:isFromMe] == true

    service_params = {
      receiver: phone_number,
      sender: Channel::WhatsappUnofficial.extract_phone_number(params[:from]), #
      sender_name: params[:pushname],
      message: extract_message_content(params), 
      message_id: params.dig(:message, :id) || params[:id]
    }

    Waha::IncomingMessageService.new(params: service_params).perform
    
    Rails.logger.info "📝 Regular message processed successfully"
  end

  def process_initial_scan(phone_number)
    Rails.logger.info "🎯 PROCESS_INITIAL_SCAN called for #{phone_number}"
    Rails.logger.info "🎯 Request ID: #{request.request_id}" if request.respond_to?(:request_id)
    Rails.logger.info "🎯 Request timestamp: #{Time.current.iso8601}"
    Rails.logger.info "🎯 Thread ID: #{Thread.current.object_id}"
    
    # Deduplication based on message ID and session ID
    message_id = params.dig(:message, :id) || params[:messageId]
    session_id = params[:sessionID] || params[:session_id]
    
    if message_id.present?
      dedup_key = "waha_callback_#{phone_number}_#{message_id}"
      
      # Check if we've already processed this exact callback
      if ::Redis::Alfred.get(dedup_key)
        Rails.logger.warn "🚫 DUPLICATE CALLBACK DETECTED for message #{message_id}. Skipping processing."
        return head :ok
      end
      
      # Mark this callback as processed (expires in 1 minute)
      ::Redis::Alfred.setex(dedup_key, "processed_#{Time.current.to_i}", 60)
      Rails.logger.info "✅ Callback marked as processed: #{dedup_key}"
    end
    
    channel = Channel::WhatsappUnofficial.find_by(phone_number: phone_number)
    unless channel
      Rails.logger.error "❌ No channel found for #{phone_number}"
      return
    end

    callback_params = params.except(:phone_number, :controller, :action)
    Rails.logger.info "🎯 About to call process_waha_callback_response with params: #{callback_params}"
    
    result = channel.process_waha_callback_response(callback_params)
    Rails.logger.info "🔍 Callback processing result: #{result}"

    case result[:action]
    when 'validate_success'
      Rails.logger.info "✅ Initial scan validation successful - session ready!"
      session_data = result[:data]
      broadcast_phone_validation_success(channel, session_data[:session_id])
      notify_session_ready(channel)
      
    when 'validate_failure'
      Rails.logger.error "❌ Initial scan validation failed. The model has already handled the broadcast."
      
    when 'validate_failure_auto_deleted'
      Rails.logger.error "❌ Initial scan validation failed and inbox was auto-deleted."
      # Broadcast auto-deletion to frontend
      broadcast_inbox_auto_deleted(channel, result[:data])
      
    else
      Rails.logger.info "📋 No specific action needed for callback type: #{result[:type]}"
    end
  end

  def process_message(phone_number)
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
    else
      Rails.logger.info "📨 Unknown message action: #{result[:action]}"
    end
  end

  def process_state_change(phone_number)
    state_data = params.except(:phone_number, :controller, :action)
    
    Rails.logger.info "WAHA state change for #{phone_number}: #{state_data}"
    
    return if state_data.blank?
    return unless state_data[:state] == 'disconnected'
    
    channel = Channel::WhatsappUnofficial.find_by(phone_number: phone_number)
    if channel
      channel.update!(token: nil)
      Rails.logger.info "Token cleared for disconnected session: #{phone_number}"
      
      broadcast_session_status_change(channel, 'disconnected')
    end
  end

  def process_qr_code(phone_number)
    qr_payload = params.except(:phone_number, :controller, :action)
    
    Rails.logger.info "QR Code event for #{phone_number}: #{qr_payload}"
    
    return if qr_payload.blank?
    
    qr_data = qr_payload[:qr]
    return unless qr_data
    
    channel = Channel::WhatsappUnofficial.find_by(phone_number: phone_number)
    return unless channel
    
    broadcast_qr_code(channel, qr_data)
  end

  def broadcast_session_status_change(channel, status)
    Rails.logger.info "📻 Broadcasting session status change for #{channel.phone_number}: #{status}"
    
    inbox = channel.inbox
    account = inbox.account
    pubsub_token = "#{account.id}_inbox_#{inbox.id}"
    
    ActionCable.server.broadcast(pubsub_token, {
      event: 'whatsapp_status_changed',
      type: 'session_status_changed', 
      status: status,
      phone_number: channel.phone_number,
      connected: status == 'logged_in',
      inbox_id: inbox.id,
      channel_id: channel.id,
      account_id: account.id,
      timestamp: Time.current.iso8601
    })
  end

  def broadcast_qr_code(channel, qr_data)
    Rails.logger.info "Broadcasting QR code for #{channel.phone_number}"
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
      account_id: account.id,
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

  def broadcast_session_mismatch(channel, connected_phone, current_attempts = nil, max_attempts = nil)
    Rails.logger.info "Broadcasting session mismatch for #{channel.phone_number}"
    Rails.logger.info "🔍 Broadcast params - current_attempts: #{current_attempts}, max_attempts: #{max_attempts}"
    
    # Check if mismatch was already broadcasted recently to prevent spam
    mismatch_cache_key = "mismatch_broadcast_#{channel.phone_number}"
    return if ::Redis::Alfred.exists?(mismatch_cache_key)
    
    ::Redis::Alfred.setex(mismatch_cache_key, true, 30.seconds.to_i)
    
    inbox = channel.inbox
    return unless inbox

    account = inbox.account
    pubsub_token = "#{account.id}_inbox_#{inbox.id}"

    # Check if this is a rescan context
    current_rescan_attempts = channel.read_rescan_attempts_from_cache
    is_rescan = current_rescan_attempts > 0

    remaining_attempts = max_attempts && current_attempts ? max_attempts - current_attempts : nil
    Rails.logger.info "🔍 Calculated remaining_attempts: #{remaining_attempts}"
    Rails.logger.info "🔍 Rescan context - is_rescan: #{is_rescan}, rescan_attempts: #{current_rescan_attempts}"
    
    message = if remaining_attempts
                if is_rescan
                  "WhatsApp number mismatch detected during rescan. #{remaining_attempts} attempts remaining."
                else
                  "WhatsApp number mismatch detected. #{remaining_attempts} attempts remaining."
                end
              else
                if is_rescan
                  'WhatsApp number mismatch detected during rescan. Please scan QR code with the correct phone number.'
                else
                  'WhatsApp number mismatch detected. Please scan QR code with the correct phone number.'
                end
              end
    
    broadcast_data = {
      event: 'whatsapp_status_changed',
      type: 'session_mismatch',
      status: 'mismatch',
      expected_phone: channel.phone_number,
      connected_phone: connected_phone,
      current_attempts: current_attempts,
      max_attempts: max_attempts,
      remaining_attempts: remaining_attempts,
      rescan_context: is_rescan,
      rescan_attempts: current_rescan_attempts,
      message: message,
      inbox_id: inbox.id,
      channel_id: channel.id
    }
    
    Rails.logger.info "📡 Broadcasting WebSocket message: #{broadcast_data.inspect}"
    
    ActionCable.server.broadcast(pubsub_token, broadcast_data)
  end

  def broadcast_session_failed(channel, connected_phone, failed_attempts)
    Rails.logger.info "Broadcasting session failed for #{channel.phone_number} after #{failed_attempts} attempts"
    
    # Handle auto-delete if maximum attempts reached
    deletion_result = channel.handle_failed_validation_attempts
    
    # Broadcast ke frontend untuk memberitahu user bahwa sudah gagal total
    inbox = channel.inbox
    return unless inbox

    account = inbox.account
    pubsub_token = "#{account.id}_inbox_#{inbox.id}"

    message = if deletion_result[:auto_deleted]
                'Failed to connect WhatsApp after 3 attempts. The platform has been automatically removed from your list.'
              else
                "Failed to connect WhatsApp after 3 attempts. #{deletion_result[:remaining_attempts]} attempts remaining."
              end

    ActionCable.server.broadcast(pubsub_token, {
      event: 'whatsapp_status_changed',
      type: 'session_failed',
      status: 'failed',
      expected_phone: channel.phone_number,
      connected_phone: connected_phone,
      failed_attempts: failed_attempts,
      auto_deleted: deletion_result[:auto_deleted],
      message: message,
      inbox_id: inbox.id,
      channel_id: channel.id
    })
  end

  def broadcast_inbox_auto_deleted(channel, deletion_data)
    Rails.logger.info "Broadcasting inbox auto-deletion for #{channel.phone_number}"
    
    inbox = channel.inbox
    return unless inbox

    account = inbox.account
    pubsub_token = "#{account.id}_inbox_#{inbox.id}"

    ActionCable.server.broadcast(pubsub_token, {
      event: 'whatsapp_status_changed',
      type: 'inbox_auto_deleted',
      status: 'auto_deleted',
      expected_phone: channel.phone_number,
      failed_attempts: deletion_data[:attempts],
      message: 'Platform WhatsApp telah dihapus otomatis karena gagal terhubung setelah 3 kali percobaan.',
      inbox_id: inbox.id,
      channel_id: channel.id,
      auto_deleted: true
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