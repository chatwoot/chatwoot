# == Schema Information
#
# Table name: channel_whatsapp_unofficials
#
#  id           :bigint           not null, primary key
#  phone_number :string           not null
#  token        :string
#  webhook_url  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#
# Indexes
#
#  index_channel_whatsapp_unofficials_on_account_id    (account_id)
#  index_channel_whatsapp_unofficials_on_phone_number  (phone_number) UNIQUE
#

class Channel::WhatsappUnofficial < ApplicationRecord
  include Channelable

  self.table_name = 'channel_whatsapp_unofficials'
  EDITABLE_ATTRS = [:token].freeze

  before_destroy :clear_session_status_cache
  before_destroy :clear_rescan_attempts

  before_destroy :clear_session_status_cache

  validates :phone_number, presence: true
  validates :account_id, presence: true
  validates :webhook_url, length: { maximum: Limits::URL_LENGTH_LIMIT }

  belongs_to :account
  has_one :inbox, as: :channel, dependent: :destroy

  def name
    'WhatsApp (Unofficial)'
  end

  def clear_session_status_cache
    ::Redis::Alfred.delete(session_status_cache_key)
  end

  def send_message(params)
    waha_service = Waha::WahaService.instance

    if params[:location].present?
      location_data = params[:location]
      return waha_service.send_location(
        api_key: token,
        phone_number: params[:to],
        latitude: location_data[:latitude],
        longitude: location_data[:longitude],
        name: location_data[:name],
        address: location_data[:address]
      )
    end

    if params[:image_path].present?
      return waha_service.send_image(
        api_key: token,
        phone_number: params[:to],
        image_path: params[:image_path],
        caption: params[:message] || ''
      )
    end

    if params[:message].present?
      return waha_service.send_text(
        api_key: token,
        phone_number: params[:to],
        message: params[:message]
      )
    end

    Rails.logger.warn "WAHA send_message called with no content for #{params[:to]}"
  end

  def qr_code
    if token.blank?
      Rails.logger.error "Cannot get QR code for phone #{phone_number}: token is blank"
      return nil
    end

    begin
      Rails.logger.info "Requesting QR code from WAHA for phone #{phone_number}"
      
      waha_service = Waha::WahaService.instance
      result = waha_service.get_qr_code_base64(api_key: token)
      
      Rails.logger.info "WAHA response for phone #{phone_number}: #{result}"
      
      # WAHA service mengembalikan QR code dalam format:
      # { "success": true, "data": { "qr_base64": "base64_string" } }
      qr_base64 = result.dig('data', 'qr_base64')
      
      if qr_base64.present?
        Rails.logger.info "QR code successfully retrieved for phone #{phone_number}"
        qr_base64
      else
        Rails.logger.error "QR code not found in WAHA response for phone #{phone_number}: #{result}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "Failed to get QR code for phone #{phone_number}: #{e.message}"
      Rails.logger.error "Error details: #{e.class.name} - #{e.backtrace&.first}"
      nil
    end
  end

  # Method untuk mendapatkan QR code (dipanggil dari InboxesController)
  # rubocop:disable Naming/AccessorMethodName
  def get_qr_code
    Rails.logger.info "Getting QR code for phone #{phone_number}, token present: #{token.present?}"

    # Check if connection has failed due to too many mismatch attempts
    cached_status = read_session_status_from_cache
    if cached_status == 'failed'
      current_attempts = read_mismatch_attempts_from_cache
      error_msg = "Cannot generate QR code - connection failed after #{current_attempts} mismatch attempts. Please try again later."
      Rails.logger.error error_msg
      raise StandardError, error_msg
    end

    if token.blank?
      Rails.logger.warn "Token is blank for #{phone_number}. Attempting to re-create device session..."
      begin
        create_device_with_retry
        reload
        Rails.logger.info "Device session re-created successfully. New token is present."
      rescue StandardError => e
        error_msg = "Failed to re-create device session to get new QR code: #{e.message}"
        Rails.logger.error error_msg
        raise StandardError, error_msg
      end
    end

    qr_data = qr_code
    if qr_data
      Rails.logger.info "QR code generated successfully for phone #{phone_number}"
      return { 'data' => { 'qr' => qr_data } }
    end

    error_msg = 'QR code not available. Make sure device is set up and session is initialized.'
    Rails.logger.error "QR code failed for phone #{phone_number}: #{error_msg}"
    raise StandardError, error_msg
  end
  # rubocop:enable Naming/AccessorMethodName

  def session_status_cache_key
    "whatsapp_session_status_#{phone_number}"
  end

  def mismatch_attempts_cache_key
    "whatsapp_mismatch_attempts_#{phone_number}"
  end

  def rescan_attempts_cache_key
    "whatsapp_rescan_attempts_#{phone_number}"
  end

  def read_session_status_from_cache
    ::Redis::Alfred.get(session_status_cache_key)
  end

  def read_mismatch_attempts_from_cache
    ::Redis::Alfred.get(mismatch_attempts_cache_key).to_i
  end

  def read_rescan_attempts_from_cache
    ::Redis::Alfred.get(rescan_attempts_cache_key).to_i
  end

  def increment_rescan_attempts
    key = rescan_attempts_cache_key
    current_value = ::Redis::Alfred.get(key).to_i
    Rails.logger.info "REDIS: Current rescan attempts before increment: #{current_value} for #{phone_number}"
    
    new_attempts = ::Redis::Alfred.incr(key)
    
    # Set expiry only on first increment (24 hours)
    ::Redis::Alfred.expire(key, 24.hours.to_i) if new_attempts == 1
    
    Rails.logger.info "REDIS: Incremented rescan attempts to #{new_attempts} for #{phone_number}"
    new_attempts
  end

  def clear_rescan_attempts
    ::Redis::Alfred.delete(rescan_attempts_cache_key)
    Rails.logger.info "REDIS: Cleared rescan attempts for #{phone_number}"
  end

  def increment_mismatch_attempts
    key = mismatch_attempts_cache_key
    lock_key = "increment_lock_#{phone_number}"
    last_increment_key = "last_increment_#{phone_number}"
    lock_value = "lock_#{Time.current.to_f}_#{SecureRandom.hex(4)}"
    
    # Check if there was a recent increment (within 3 seconds) to prevent rapid increments
    last_increment_time = ::Redis::Alfred.get(last_increment_key)
    if last_increment_time
      time_since_last = Time.current.to_f - last_increment_time.to_f
      if time_since_last < 3.0 # Less than 3 seconds since last increment
        Rails.logger.warn "🚫 Rapid increment blocked! Last increment was #{time_since_last.round(2)}s ago"
        return ::Redis::Alfred.get(key).to_i
      end
    end
    
    # Try to acquire increment lock to prevent race conditions
    acquired_lock = ::Redis::Alfred.set(lock_key, lock_value, nx: true, ex: 5)
    
    unless acquired_lock
      Rails.logger.warn "🔒 Increment locked for #{phone_number}. Returning current value to prevent duplicate."
      return ::Redis::Alfred.get(key).to_i
    end
    
    begin
      # Get current value and increment atomically
      current_value = ::Redis::Alfred.get(key).to_i
      Rails.logger.info "REDIS: Current attempts before increment: #{current_value} for #{phone_number}"
      
      new_attempts = ::Redis::Alfred.incr(key)
      
      # Set expiry only on first increment
      ::Redis::Alfred.expire(key, 1.hour.to_i) if new_attempts == 1
      
      # Record the time of this increment to prevent rapid increments
      ::Redis::Alfred.setex(last_increment_key, Time.current.to_f.to_s, 10)
      
      Rails.logger.info "REDIS: Incremented mismatch attempts to #{new_attempts} for #{phone_number}"
      
      # If there's a suspicious jump, log it for debugging
      if current_value.positive? && new_attempts > current_value + 1
        Rails.logger.warn "⚠️ SUSPICIOUS: Attempts jumped from #{current_value} to #{new_attempts} for #{phone_number}"
      end
      
      new_attempts
      
    ensure
      # Always release the lock if we own it
      if ::Redis::Alfred.get(lock_key) == lock_value
        ::Redis::Alfred.del(lock_key)
        Rails.logger.debug { "🔓 Released increment lock for #{phone_number}" }
      end
    end
  end

  def clear_mismatch_attempts
    ::Redis::Alfred.delete(mismatch_attempts_cache_key)
    Rails.logger.info "REDIS: Cleared mismatch attempts for #{phone_number}"
  end

  def write_session_status_to_cache(status, expires_in: 24.hours)
    ::Redis::Alfred.setex(session_status_cache_key, status, expires_in.to_i)
    Rails.logger.info "REDIS: Wrote '#{status}' to #{session_status_cache_key}"
  end

  def clear_session_status_cache
    ::Redis::Alfred.delete(session_status_cache_key)
    Rails.logger.info "REDIS: Cleared cache for #{session_status_cache_key}"
  end

  # Method untuk mengecek status session dengan validasi real-time
  def session_status
    Rails.logger.info "🔍 Checking session status for #{phone_number} using cache"

    # Jika tidak ada token, sudah pasti tidak terhubung
    unless token.present?
      return { 'data' => { 'connected' => false, 'status' => 'not_logged_in' } }
    end

    # Baca status dari cache
    cached_status = read_session_status_from_cache

    Rails.logger.info "CACHE: Read '#{cached_status}' for #{phone_number}"

    case cached_status
    when 'validated'
      { 'data' => { 'connected' => true, 'status' => 'logged_in' } }
    when 'mismatch'
      { 'data' => { 'connected' => false, 'status' => 'mismatch' } }
    when 'waiting'
      { 'data' => { 'connected' => false, 'status' => 'waiting_for_qr' } }
    else
      # Token ada, tapi belum ada validasi di cache. Menunggu scan.
      { 'data' => { 'connected' => false, 'status' => 'pending_validation' } }
    end
  end

  # Method untuk real-time status checking langsung ke WAHA API tanpa cache
  def real_time_status
    Rails.logger.info "🔍 Checking real-time status for #{phone_number} from WAHA API"

    # Jika tidak ada token, sudah pasti tidak terhubung
    unless token.present?
      return { 'data' => { 'connected' => false, 'status' => 'not_logged_in' } }
    end

    # Get previous status for comparison
    previous_status = read_session_status_from_cache

    begin
      waha_service = Waha::WahaService.instance
      result = waha_service.get_session_status(api_key: token)
      
      Rails.logger.info "WAHA real-time status response for #{phone_number}: #{result}"
      
      # Parse WAHA response - using new session/info endpoint with logged_in/not_logged_in
      waha_status = result.dig('data', 'status') || 'not_logged_in'
      connected = waha_status.downcase == 'logged_in'
      
      # Determine current status
      current_status = connected ? 'connected' : 'disconnected'
      
      # Detect status change and handle disconnect
      if previous_status != current_status
        Rails.logger.info "🔄 Status changed for #{phone_number}: #{previous_status} → #{current_status}"
        
        if current_status == 'disconnected'
          handle_auto_disconnect
        elsif current_status == 'connected'
          handle_auto_reconnect
        end
        
        # Update cache with new status
        write_session_status_to_cache(current_status)
      end
      
      # Format response sesuai dengan format yang diharapkan frontend
      {
        'data' => {
          'connected' => connected,
          'status' => connected ? 'logged_in' : 'not_logged_in'
        }
      }
    rescue StandardError => e
      Rails.logger.error "Failed to get real-time status for #{phone_number}: #{e.message}"
      
      # If API fails, assume disconnected and handle it
      if previous_status == 'connected'
        Rails.logger.warn "API failed, assuming #{phone_number} is disconnected"
        handle_auto_disconnect
        write_session_status_to_cache('disconnected')
      end
      
      # Return disconnected status on error
      {
        'data' => {
          'connected' => false,
          'status' => 'not_logged_in'
        }
      }
    end
  end

  def set_webhook_url
    base_url = current_application_url
    webhook = "#{base_url}/waha/callback/#{phone_number}"
    
    update!(webhook_url: webhook)
    Rails.logger.info "Webhook URL set for phone #{phone_number}: #{webhook}"
    webhook
  rescue StandardError => e
    Rails.logger.error "Failed to set webhook URL for phone #{phone_number}: #{e.message}"
    # Set default webhook URL sebagai fallback
    fallback_webhook = "#{current_application_url}/waha/callback/#{phone_number}"
    update!(webhook_url: fallback_webhook)
    fallback_webhook
  end

  # Method untuk filter dan validate response dari WAHA callback berdasarkan 4 jenis callback aktual
  def process_waha_callback_response(callback_params)
    Rails.logger.info '🔍 Processing WAHA callback for #{phone_number}'
    Rails.logger.info '🔍 Callback params: #{callback_params.inspect}'
    
    # Determine event type berdasarkan struktur callback WAHA yang sebenarnya
    event_type = self.class.determine_event_type(callback_params)
    Rails.logger.info '🎯 Event type determined: #{event_type}'
    
    case event_type
    when 'receipt'
      # Callback #1: Receipt untuk read/delivered status
      Rails.logger.info '📬 Receipt callback - updating message status only'
      return { type: 'receipt', action: 'update_message_status' }
      
    when 'message'
      # Callback #2 dan #3: Regular messages (ada pushname)
      Rails.logger.info '� Regular message callback - no phone validation needed'
      return { type: 'regular_message', action: 'process_normally' }
      
    when 'initial_scan'
      # Callback #4: Initial scan result (TIDAK ada pushname) - PERLU VALIDASI!
      Rails.logger.info '🎯 Initial scan callback detected - validating phone number'
      
      # Extract phone number dari field "from"
      connected_phone = self.class.extract_phone_from_from_field(callback_params[:from])
      Rails.logger.info "📋 Connected phone from callback: #{connected_phone}"
      Rails.logger.info "📋 Expected device phone: #{phone_number}"
      
      # ✅ GUNAKAN VALIDASI BARU YANG COMPREHENSIVE
      Rails.logger.info "🔄 Calling validate_callback_phone_number method..."
      validation_result = validate_callback_phone_number(connected_phone)
      Rails.logger.info "🔍 Validation result: #{validation_result.inspect}"
      
      if validation_result[:success]
        Rails.logger.info "✅ Phone validation SUCCESS via new method"
        session_id = callback_params[:sessionID]
        return { 
          type: 'initial_scan', 
          action: 'validate_success', 
          data: {
            session_id: session_id,
            phone_number: phone_number,
            connected_phone: connected_phone,
            validation_status: 'validated'
          }
        }
      else
        Rails.logger.error "❌ Phone validation FAILED via new method"
        
        # Check if auto-deletion occurred
        if validation_result[:auto_deleted]
          return { 
            type: 'initial_scan', 
            action: 'validate_failure_auto_deleted', 
            data: validation_result.merge({
              session_id: callback_params[:sessionID],
              auto_deleted: true
            })
          }
        else
          return { 
            type: 'initial_scan', 
            action: 'validate_failure', 
            data: validation_result.merge({
              session_id: callback_params[:sessionID]
            })
          }
        end
      end
      
    else
      # Unknown callback type
      Rails.logger.info '� Unknown callback type: #{event_type} - processing normally'
      return { type: 'unknown', action: 'process_normally' }
    end
  end

  # Method untuk restart session (untuk re-scanning QR)
  def restart_session_for_rescan
    Rails.logger.info "🔄 Starting COMPLETE restart for: #{phone_number}"

    # DON'T clear mismatch attempts - keep tracking for rescan schema
    # Only clear session status cache
    clear_session_status_cache
    
    # Increment rescan attempts for tracking
    rescan_attempts = increment_rescan_attempts
    Rails.logger.info "📊 This is rescan attempt ##{rescan_attempts} for #{phone_number}"
    
    # Check if max rescan attempts reached
    if rescan_attempts > 3
      Rails.logger.error "❌ Maximum rescan attempts (3) reached for #{phone_number}"
      return handle_failed_rescan_attempts
    end
    
    begin
      old_token = token
      
      if old_token.present?
        waha_service = Waha::WahaService.instance
        
        # Step 1: Logout old session
        Rails.logger.info "🚪 Logging out old session for: #{phone_number}"
        begin
          logout_result = waha_service.logout_session(api_key: old_token)
          Rails.logger.info "Logout result: #{logout_result}"
        rescue => e
          Rails.logger.warn "Logout failed (acceptable): #{e.message}"
        end
        
        # Step 2: Delete old device from WAHA server
        Rails.logger.info "🗑️ Deleting old device from WAHA: #{old_token}"
        begin
          delete_result = waha_service.delete_session(api_key: old_token)
          Rails.logger.info "Delete device result: #{delete_result}"
        rescue => e
          Rails.logger.warn "Delete device failed (acceptable): #{e.message}"
        end
        
        # Step 3: Clear old token from database
        Rails.logger.info "🔄 Clearing old token from database"
        update!(token: nil)
      end
      
      # Step 4: Create completely new device with new token
      Rails.logger.info "🆕 Creating new device session for #{phone_number}"
      create_device_with_retry
      reload # Get the new token
      
      # Step 5: Initialize new session with new token
      if token.present?
        Rails.logger.info "🔄 Initializing new session with token: #{token[0..8]}..."
        waha_service = Waha::WahaService.instance
        initialize_result = waha_service.initialize_whatsapp_session(api_key: token)
        Rails.logger.info "Initialize new session result: #{initialize_result}"
      end
      
      # Step 6: Set status for QR generation
      write_session_status_to_cache('waiting')
      
      # Step 7: Clear QR cache to force new QR generation
      qr_cache_key = "whatsapp_qr_#{phone_number}"
      ::Redis::Alfred.delete(qr_cache_key)
      Rails.logger.info "🗑️ Cleared QR cache for #{phone_number}"
      
      return {
        success: true,
        message: 'New device session created. Ready for QR scanning.',
        status: 'waiting',
        method: 'complete_restart',
        old_token: old_token.present? ? "#{old_token[0..8]}..." : 'none',
        new_token: token.present? ? "#{token[0..8]}..." : 'none'
      }
      
    rescue StandardError => e
      Rails.logger.error "Failed to complete restart for #{phone_number}: #{e.message}"
      Rails.logger.error "Error backtrace: #{e.backtrace&.first(3)&.join("\n")}"
      
      # Force reset even on error
      write_session_status_to_cache('waiting')
      
      return {
        success: true,  # Return success to allow retry
        message: 'Session reset forced. Ready for QR scanning.',
        status: 'waiting',
        method: 'force_reset',
        warning: e.message
      }
    end
  end

  # Method untuk handle failed attempts dan auto-delete inbox
  def handle_failed_validation_attempts
    current_attempts = read_mismatch_attempts_from_cache
    max_attempts = 3

    Rails.logger.info "📊 Checking failed attempts for #{phone_number}: #{current_attempts}/#{max_attempts}"

    if current_attempts >= max_attempts
      Rails.logger.error "❌ Maximum attempts reached for #{phone_number}. Auto-deleting inbox..."
      
      # Mark as failed and delete the inbox
      write_session_status_to_cache('failed', expires_in: 1.hour)
      
      # Disconnect WAHA session
      disconnect_waha_session
      
      # Schedule inbox deletion
      delete_inbox_after_failed_attempts
      
      {
        success: false,
        auto_deleted: true,
        attempts: current_attempts,
        max_attempts: max_attempts,
        message: "Failed to connect after #{max_attempts} attempts. Inbox has been automatically removed."
      }
    else
      remaining = max_attempts - current_attempts
      {
        success: false,
        auto_deleted: false,
        attempts: current_attempts,
        max_attempts: max_attempts,
        remaining_attempts: remaining,
        message: "Phone number mismatch detected. #{remaining} attempts remaining."
      }
    end
  end

  # Method untuk handle failed rescan attempts
  def handle_failed_rescan_attempts
    current_attempts = read_rescan_attempts_from_cache
    max_attempts = 3

    Rails.logger.info "📊 Checking failed rescan attempts for #{phone_number}: #{current_attempts}/#{max_attempts}"

    if current_attempts >= max_attempts
      Rails.logger.error "❌ Maximum rescan attempts reached for #{phone_number}. Auto-deleting inbox..."
      
      # Mark as failed and delete the inbox
      write_session_status_to_cache('failed', expires_in: 1.hour)
      
      # Disconnect WAHA session
      disconnect_waha_session
      
      # Schedule inbox deletion
      delete_inbox_after_failed_attempts
      
      {
        success: false,
        auto_deleted: true,
        attempts: current_attempts,
        max_attempts: max_attempts,
        message: "Failed to reconnect after #{max_attempts} rescan attempts. Inbox has been automatically removed."
      }
    else
      remaining = max_attempts - current_attempts
      {
        success: false,
        auto_deleted: false,
        attempts: current_attempts,
        max_attempts: max_attempts,
        remaining_attempts: remaining,
        message: "Phone number mismatch detected during rescan. #{remaining} attempts remaining."
      }
    end
  end

  def delete_inbox_after_failed_attempts
    Rails.logger.error "🗑️ Auto-deleting inbox due to failed validation attempts for #{phone_number}"
    
    begin
      # Disconnect WAHA session first
      disconnect_waha_session if token.present?
      
      # Clear all cache
      clear_session_status_cache
      clear_mismatch_attempts
      
      # Delete the inbox (this will also delete the channel due to dependent: :destroy)
      if inbox.present?
        inbox_name = inbox.name
        inbox.destroy!
        Rails.logger.info "✅ Inbox '#{inbox_name}' auto-deleted successfully"
        
        # Optionally send notification to admin
        # AdminNotificationMailer.whatsapp_inbox_auto_deleted(self, inbox_name).deliver_later
        
        true
      else
        Rails.logger.warn "⚠️ No inbox found to delete for channel #{phone_number}"
        false
      end
    rescue StandardError => e
      Rails.logger.error "❌ Failed to auto-delete inbox for #{phone_number}: #{e.message}"
      false
    end
  end

  private

  # Handle auto-detected disconnect (tanpa webhook)
  def handle_auto_disconnect
    Rails.logger.warn "🔌 Auto-detected disconnect for #{phone_number}"
    
    # Clear mismatch attempts karena ini disconnect beneran
    clear_mismatch_attempts
    
    # Broadcast disconnect event via WebSocket
    broadcast_disconnect_event
  end

  # Handle auto-detected reconnect
  def handle_auto_reconnect  
    Rails.logger.info "🔌 Auto-detected reconnect for #{phone_number}"
    
    # Clear any failure cache
    clear_mismatch_attempts
    
    # Broadcast reconnect event via WebSocket
    broadcast_reconnect_event
  end

  # Broadcast disconnect event to frontend
  def broadcast_disconnect_event
    begin
      # Broadcast to inbox-specific token (for specific monitoring)
      inbox_pubsub_token = "#{account_id}_inbox_#{inbox.id}"
      
      Rails.logger.info "🔊 Broadcasting auto-detected disconnect for #{phone_number}"
      Rails.logger.info "🔊 Inbox PubSub Token: #{inbox_pubsub_token}"
      Rails.logger.info "🔊 Account ID: #{account_id}, Inbox ID: #{inbox.id}"
      
      broadcast_data = {
        event: 'whatsapp_status_changed',
        type: 'auto_disconnect',
        status: 'disconnected',
        connected: false,
        phone_number: phone_number,
        inbox_id: inbox.id,
        account_id: account_id,
        timestamp: Time.current.iso8601
      }
      
      Rails.logger.info "🔊 Broadcast data: #{broadcast_data.inspect}"
      
      # Broadcast to inbox-specific token
      ActionCable.server.broadcast(inbox_pubsub_token, broadcast_data)
      
      # Also broadcast to all users in this account for real-time updates in list views
      account = Account.find(account_id)
      account.users.each do |user|
        user_pubsub_token = user.pubsub_token
        Rails.logger.info "🔊 Also broadcasting to user #{user.id} with token: #{user_pubsub_token}"
        ActionCable.server.broadcast(user_pubsub_token, broadcast_data)
      end
      
      Rails.logger.info "✅ Disconnect event broadcasted successfully"
    rescue StandardError => e
      Rails.logger.error "❌ Failed to broadcast disconnect event: #{e.message}"
      Rails.logger.error "❌ Error backtrace: #{e.backtrace&.first(3)&.join("\n")}"
    end
  end

  # Broadcast reconnect event to frontend  
  def broadcast_reconnect_event
    begin
      # Broadcast to inbox-specific token (for specific monitoring)
      inbox_pubsub_token = "#{account_id}_inbox_#{inbox.id}"
      
      Rails.logger.info "🔊 Broadcasting auto-detected reconnect for #{phone_number}"
      Rails.logger.info "🔊 Inbox PubSub Token: #{inbox_pubsub_token}"
      
      broadcast_data = {
        event: 'whatsapp_status_changed',
        type: 'auto_reconnect', 
        status: 'connected',
        connected: true,
        phone_number: phone_number,
        inbox_id: inbox.id,
        account_id: account_id,
        timestamp: Time.current.iso8601
      }
      
      Rails.logger.info "🔊 Broadcast data: #{broadcast_data.inspect}"
      
      # Broadcast to inbox-specific token
      ActionCable.server.broadcast(inbox_pubsub_token, broadcast_data)
      
      # Also broadcast to all users in this account for real-time updates in list views
      account = Account.find(account_id)
      account.users.each do |user|
        user_pubsub_token = user.pubsub_token
        Rails.logger.info "🔊 Also broadcasting to user #{user.id} with token: #{user_pubsub_token}"
        ActionCable.server.broadcast(user_pubsub_token, broadcast_data)
      end
      
      Rails.logger.info "✅ Reconnect event broadcasted successfully"
    rescue StandardError => e
      Rails.logger.error "❌ Failed to broadcast reconnect event: #{e.message}"
      Rails.logger.error "❌ Error backtrace: #{e.backtrace&.first(3)&.join("\n")}"
    end
  end

  def validate_callback_phone_number(callback_phone)
    Rails.logger.info "🔍 VALIDATE_CALLBACK_PHONE_NUMBER called with: #{callback_phone}"
    Rails.logger.info "🔍 Expected phone: #{phone_number}"
    Rails.logger.info "🔍 Request timestamp: #{Time.current.iso8601}"

    lock_key = "validation_lock_#{phone_number}"
    lock_value = "#{Time.current.to_f}_#{SecureRandom.hex(4)}" # Unique lock value
    
    # Try to acquire lock with unique value (10 seconds duration to handle multiple WAHA callbacks)
    is_locked = !::Redis::Alfred.set(lock_key, lock_value, nx: true, ex: 10)

    if is_locked
      existing_lock_value = ::Redis::Alfred.get(lock_key)
      Rails.logger.warn "🔒 Validation for #{phone_number} is currently locked by #{existing_lock_value}. Current attempt: #{lock_value}"
      
      # Check if this is a legitimate retry (after 5+ seconds) or a race condition callback
      if existing_lock_value
        begin
          lock_time = existing_lock_value.split('_')[0].to_f
          time_held = Time.current.to_f - lock_time
          
          Rails.logger.info "🕐 Lock has been held for #{time_held.round(2)} seconds"
          
          if time_held > 5.0 # If lock is older than 5 seconds, this might be a legitimate retry
            Rails.logger.warn "🔓 Breaking stale lock (held for #{time_held.round(2)}s) - potential legitimate retry"
            if ::Redis::Alfred.get(lock_key) == existing_lock_value
              ::Redis::Alfred.set(lock_key, lock_value, ex: 10)
              is_locked = false
            end
          else
            # This is likely a race condition callback, not a legitimate retry
            Rails.logger.warn "🚫 Rejecting callback - likely race condition (lock held for only #{time_held.round(2)}s)"
          end
        rescue StandardError => e
          Rails.logger.error "Error checking lock time: #{e.message}"
        end
      end
      
      if is_locked
        Rails.logger.warn "🔒 Still locked. Skipping duplicate/race condition callback."
        return { success: false, status: 'locked', message: 'Validation in progress or duplicate callback' }
      else
        Rails.logger.info "🔓 Lock acquired after breaking stale lock"
      end
    else
      Rails.logger.info "🔓 Lock acquired immediately"
    end

    begin
      expected_clean = normalize_phone_number(phone_number)
      callback_clean = normalize_phone_number(self.class.sanitize_phone_number(callback_phone))
      
      Rails.logger.info "🔍 Normalized expected: #{expected_clean}"
      Rails.logger.info "🔍 Normalized callback: #{callback_clean}"

      if expected_clean == callback_clean
        Rails.logger.info "✅ Phone validation SUCCESS - numbers match!"
        clear_mismatch_attempts
        clear_rescan_attempts # Also clear rescan attempts on success
        write_session_status_to_cache('validated')

        return {
          success: true,
          status: 'validated',
          message: 'Phone number validation successful'
        }
      else
        Rails.logger.error "❌ Phone validation FAILED - phone mismatch detected"
        Rails.logger.error "❌ Expected: #{expected_clean}, Got: #{callback_clean}"
        
        # Check if this is a rescan attempt (rescan attempts exist)
        current_rescan_attempts = read_rescan_attempts_from_cache
        is_rescan = current_rescan_attempts > 0
        
        Rails.logger.info "📊 Mismatch context - is_rescan: #{is_rescan}, rescan_attempts: #{current_rescan_attempts}"
        
        current_attempts = increment_mismatch_attempts
        max_attempts = 3
        
        if is_rescan
          Rails.logger.error "❌ Rescan mismatch attempt #{current_attempts}/#{max_attempts} (rescan session ##{current_rescan_attempts})"
        else
          Rails.logger.error "❌ Initial scan mismatch attempt #{current_attempts}/#{max_attempts}"
        end

        if current_attempts >= max_attempts
          Rails.logger.error "❌ Maximum mismatch attempts (#{max_attempts}) reached for #{phone_number}"
          Rails.logger.error "❌ Initiating auto-deletion process..."
          
          write_session_status_to_cache('failed', expires_in: 1.hour)
          
          disconnect_result = disconnect_waha_session
          Rails.logger.error "❌ Disconnect result: #{disconnect_result}"
          
          controller = Waha::CallbackController.new
          controller.send(:broadcast_session_failed, self, callback_phone, current_attempts)

          return {
            success: false,
            status: 'failed',
            attempts: current_attempts,
            max_attempts: max_attempts,
            auto_deleted: true,
            message: is_rescan ? "Phone number validation failed after #{max_attempts} attempts during rescan." : "Phone number validation failed after #{max_attempts} attempts.",
            rescan_context: is_rescan
          }
        else
          Rails.logger.error "❌ Setting mismatch status and disconnecting session"
          write_session_status_to_cache('mismatch', expires_in: 10.minutes)
          logout_result = disconnect_waha_session
          Rails.logger.error "❌ Logout result: #{logout_result}"

          controller = Waha::CallbackController.new
          controller.send(:broadcast_session_mismatch, self, callback_phone, current_attempts, max_attempts)

          return {
            success: false,
            status: 'mismatch',
            attempts: current_attempts,
            max_attempts: max_attempts,
            message: is_rescan ? 'Phone number mismatch during rescan - session logged out' : 'Phone number mismatch - session logged out',
            expected_phone: expected_clean,
            connected_phone: callback_clean,
            logout_result: logout_result,
            rescan_context: is_rescan
          }
        end
      end
    rescue => e
      Rails.logger.error "🔥 Error during validation: #{e.message}"
      Rails.logger.error "🔥 Backtrace: #{e.backtrace.first(5).join('\n')}"
      
      return {
        success: false,
        status: 'error',
        message: 'Validation error occurred'
      }
    ensure
      # Always release the lock regardless of outcome
      ::Redis::Alfred.delete(lock_key)
      Rails.logger.info "🔓 Lock released for #{phone_number}"
    end
  end

  def waha_configured?
    phone_number.present? && token.present?
  end

  def create_device_with_retry(max_retries: 1)
    retries = 0
    
    begin
      result = create_device_on_waha
      process_device_creation_result(result)
      
      # Initialize WhatsApp session after device creation
      initialize_whatsapp_session
    rescue StandardError => e
      retries += 1
      Rails.logger.error "Attempt #{retries} failed to create device for phone #{phone_number}: #{e.message}"
      
      if retries < max_retries
        sleep(2**retries) # Exponential backoff
        retry
      else
        Rails.logger.error "All #{max_retries} attempts failed for phone #{phone_number}"
        raise e
      end
    end
  end

  def initialize_whatsapp_session
    return if token.blank?
    
    begin
      waha_service = Waha::WahaService.instance
      result = waha_service.initialize_whatsapp_session(api_key: token)
      Rails.logger.info "WhatsApp session initialized for phone #{phone_number}: #{result}"
      result
    rescue StandardError => e
      Rails.logger.error "Failed to initialize WhatsApp session for phone #{phone_number}: #{e.message}"
      # Don't raise error here, session initialization can be retried later
      nil
    end
  end

  # Method untuk disconnect session dari WAHA (digunakan oleh callback controller)
  def disconnect_waha_session
    return if token.blank?

    begin
      waha_service = Waha::WahaService.instance
      response = waha_service.logout_session(api_key: token)

      Rails.logger.info "WAHA session logout response for #{phone_number}: #{response}"
      
      # ✅ PENTING: Hapus token dan bersihkan cache setelah logout
      update!(token: nil)
      clear_session_status_cache
      
      response
    rescue StandardError => e
      Rails.logger.error "Failed to logout WAHA session for #{phone_number}: #{e.message}"
      # Tetap bersihkan state meskipun API call gagal
      update!(token: nil)
      clear_session_status_cache
      nil
    end
  end

  # Method untuk validasi phone number consistency (digunakan oleh callback controller)
  def validate_phone_number_consistency(connected_phone)
    return true if connected_phone.blank?
    
    # Sanitize kedua nomor menggunakan method yang sama
    expected_clean = normalize_phone_number(phone_number)
    connected_clean = normalize_phone_number(self.class.sanitize_phone_number(connected_phone))
    
    Rails.logger.info 'PHONE VALIDATION:'
    Rails.logger.info "  Expected (registered): #{phone_number} -> #{expected_clean}"
    Rails.logger.info "  Connected (from callback): #{connected_phone} -> #{connected_clean}"
    Rails.logger.info "  Match result: #{expected_clean == connected_clean}"
    
    expected_clean == connected_clean
  end

  # Method untuk handle phone validation failure TANPA cache
  def handle_phone_validation_failure(actual_phone, session_id = nil)
    Rails.logger.error 'CRITICAL: Phone validation failed!'
    Rails.logger.error "  Expected: #{phone_number}"
    Rails.logger.error "  Connected: #{actual_phone}"

    # ✅ Hapus token dan bersihkan cache
    update!(token: nil)
    clear_session_status_cache
    Rails.logger.info 'Token and cache cleared due to phone validation failure'

    {
      expected_phone: phone_number,
      connected_phone: actual_phone,
      error: 'Phone number validation failed'
    }
  end

  # Method untuk handle successful phone validation TANPA cache
  def handle_phone_validation_success(session_id = nil, connected_phone = nil)
    Rails.logger.info "Phone validation successful for #{phone_number}"
    
    # ✅ Tulis status 'validated' ke cache
    write_session_status_to_cache('validated')
    
    {
      phone_number: phone_number,
      status: 'logged_in',
      phone_validated: true
    }
  end

  # Method helper untuk extract phone number dari chat ID WhatsApp
  def self.extract_phone_number(chat_id)
    return nil if chat_id.blank?
    
    # Handle format seperti "6282164497019@s.whatsapp.net" atau group format
    phone = chat_id.split.first
    phone&.gsub(/@.*$/, '')
  end

  # Method helper untuk normalize phone number
  def normalize_phone_number(phone)
    return nil if phone.blank?
    
    # Remove all non-numeric characters
    normalized = phone.gsub(/\D/, '')
    
    # Handle different Indonesian phone number formats
    case normalized
    when /^62/
      normalized # Already in international format
    when /^08/
      "62#{normalized[1..]}" # Convert 08xxx to 628xxx
    when /^0/
      "62#{normalized[1..]}" # Convert 0xxx to 62xxx
    else
      normalized # Return as is for other formats
    end
  end

  # Method untuk detect initial scan message (digunakan oleh callback controller)
  def self.initial_scan_message?(params)
    # Initial scan message characteristics (callback #4 dari contoh):
    # ✅ "from": "6281281631785@s.whatsapp.net" (tanpa " in " group format)
    # ✅ "isFromMe": true (self message)  
    # ✅ "isGroup": false
    # ✅ "message": { "id": "..." } (HANYA id, TIDAK ada text/caption)
    # ❌ "pushname": TIDAK ADA (ini kunci utama pembeda!)
    
    # 1. Harus isFromMe = true
    return false unless params[:isFromMe] == true
    
    # 2. TIDAK boleh ada pushname (ini pembeda utama dari message biasa)
    return false if params[:pushname].present?
    
    # 3. Format from harus simple (bukan group chat)
    # Group chat format: "6285842516470:31@s.whatsapp.net in 6281281631785@s.whatsapp.net"
    # Initial scan format: "6281281631785@s.whatsapp.net"
    return false if params[:from].to_s.include?(' in ')
    
    # 4. Message hanya boleh punya id, TIDAK boleh ada text/body/caption
    message = params[:message] || {}
    return false if message[:text].present?
    return false if message[:body].present?
    return false if message[:caption].present?
    return false unless message[:id].present?
    
    # 5. Harus bukan group
    return false if params[:isGroup] == true
    
    # Jika semua kondisi terpenuhi, ini adalah initial scan message
    Rails.logger.info "🎯 DETECTED INITIAL SCAN MESSAGE:"
    Rails.logger.info "  - From: #{params[:from]}"
    Rails.logger.info "  - IsFromMe: #{params[:isFromMe]}"
    Rails.logger.info "  - Pushname: #{params[:pushname] || 'NONE (correct for initial scan)'}"
    Rails.logger.info "  - Message ID: #{message[:id]}"
    Rails.logger.info "  - Has text/body: #{message[:text].present? || message[:body].present?}"
    
    true
  end

  # Method untuk extract connected phone dari callback payload
  def self.extract_connected_phone_number(payload)
    # WAHA mengirim nomor terhubung dalam format berbeda tergantung event
    # Untuk message event: payload[:from] = "628xxx@s.whatsapp.net" atau "6285842516470:31@s.whatsapp.net in 6281281631785@s.whatsapp.net"
    # Untuk session event: payload[:phone_number] atau payload[:jid]
    
    connected_phone = payload[:phone_number] ||
                      payload[:phone] ||
                      extract_phone_from_from_field(payload[:from]) ||
                      payload[:jid]&.gsub(/@.*$/, '') ||
                      payload.dig(:info, :phone_number) ||
                      payload.dig(:session, :phone_number)
    
    # Final cleanup - remove any WhatsApp suffixes
    sanitize_phone_number(connected_phone)
  end

  # Method khusus untuk extract phone dari field "from" yang complex
  def self.extract_phone_from_from_field(from_field)
    return nil if from_field.blank?
    
    # Handle different "from" formats:
    # 1. Simple: "6281281631785@s.whatsapp.net" 
    # 2. Group chat: "6285842516470:31@s.whatsapp.net in 6281281631785@s.whatsapp.net"
    # 3. Business: "628xxx@c.us"
    
    case from_field.to_s
    when /^(\d+):?\d*@.*\sin\s(\d+)@/
      # Group chat format - ambil nomor yang kedua (recipient)
      $2
    when /^(\d+):?\d*@/
      # Simple format - ambil nomor pertama
      $1
    else
      # Fallback: ambil semua digit sebelum @
      from_field.to_s.split('@').first&.gsub(/\D/, '')
    end
  end

  # Method untuk sanitize phone number dari format WhatsApp
  def self.sanitize_phone_number(phone)
    return nil if phone.blank?
    
    # Remove WhatsApp suffixes and non-numeric characters
    sanitized = phone.to_s
                     .gsub(/@(s\.whatsapp\.net|c\.us)$/, '') # Remove WhatsApp domain
                     .gsub(/:\d+$/, '') # Remove device ID (e.g., :31)
                     .gsub(/\D/, '') # Keep only digits
    
    sanitized.present? ? sanitized : nil
  end

  # Method untuk determine event type dari callback payload WAHA yang sebenarnya
  def self.determine_event_type(params)
    if params[:event] == 'receipt'
      Rails.logger.info "📬 Detected RECEIPT callback"
      return 'receipt'
    end

    if params.key?(:from) && params.key?(:isFromMe) && params.key?(:message)

      if params[:pushname].present?
        Rails.logger.info "📝 Detected a REGULAR MESSAGE (incoming, outgoing, with reply, etc.)"
        return 'message'
      
      elsif params[:isFromMe] == true && params[:pushname].blank?
        Rails.logger.info "🎯 Detected INITIAL SCAN callback"
        return 'initial_scan'
      end
    end
    Rails.logger.info "❓ Unknown callback structure"
    'unknown'
  end

  private

  def create_device_on_waha
    return { error: 'Webhook URL required' } if webhook_url.blank?
    
    waha_service = Waha::WahaService.instance
    waha_service.create_device(phone_number: phone_number, webhook_url: webhook_url)
  end

  def process_device_creation_result(result)
    # WAHA API returns "token" not "api_key"
    token_value = result&.dig('data', 'token')
    raise StandardError, "No token in response: #{result}" unless token_value
    
    update!(token: token_value)
    Rails.logger.info "Device created successfully for phone #{phone_number}, token saved: #{token_value[0..10]}..."
    result
  end

  def fetch_session_status_from_waha
    # Sekarang status session dikirim otomatis via WAHA callback
    # Tidak perlu memanggil API lagi, karena status sudah diupdate real-time
    # Return status default yang akan diupdate oleh callback
    Rails.logger.info "⚠️  No cached status available, returning fallback status"
    {
      'data' => {
        'connected' => false,
        'status' => 'not_logged_in'
      }
    }
  rescue StandardError => e
    Rails.logger.error "Error in session status check for #{phone_number}: #{e.message}"
    error_session_status
  end

  def build_session_status_response(result)
    if result.present?
      # Handle dua format:
      # 1. String langsung dari cache: "logged_in"
      # 2. Object dari API: { "data" => { "status" => "logged_in" } }
      session_status = if result.is_a?(String)
                         result
                       else
                         result.dig('data', 'status') || result['status'] || default_status
                       end
      
      # Status connected jika session_status adalah 'logged_in'
      connected = session_status == 'logged_in'
      
      {
        'data' => {
          'connected' => connected,
          'status' => session_status
        }
      }
    else
      fallback_session_status
    end
  end

  def default_status
    'not_logged_in'
  end

  def fallback_session_status
    {
      'data' => {
        'connected' => false,
        'status' => 'not_logged_in'
      }
    }
  end

  def error_session_status
    {
      'data' => {
        'connected' => false,
        'status' => 'not_logged_in'
      }
    }
  end

  def current_application_url
    # Priority: FRONTEND_URL env var, then Rails URL helpers, then fallback
    return ENV['FRONTEND_URL'] if ENV['FRONTEND_URL'].present?
    
    # Fallback to generating URL from Rails
    if defined?(Rails.application.routes.url_helpers)
      begin
        Rails.application.routes.url_helpers.root_url
      rescue StandardError
        detect_current_url_from_request || 'http://localhost:3000'
      end
    else
      detect_current_url_from_request || 'http://localhost:3000'
    end
  end

  def detect_current_url_from_request
    # Try to get URL from current request context if available
    return nil unless defined?(Current) && Current.respond_to?(:request)
    
    request = Current.request
    return nil unless request&.respond_to?(:base_url)
    
    request.base_url
  rescue StandardError
    nil
  end
end
