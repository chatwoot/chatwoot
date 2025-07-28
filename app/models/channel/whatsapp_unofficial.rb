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
    Rails.cache.delete(session_status_cache_key)
    Rails.logger.info "CACHE: Cleared cache for #{session_status_cache_key}"
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

  def read_session_status_from_cache
    Rails.cache.read(session_status_cache_key)
  end

  def write_session_status_to_cache(status, expires_in: 24.hours)
    Rails.cache.write(session_status_cache_key, status, expires_in: expires_in)
    Rails.logger.info "CACHE: Wrote '#{status}' to #{session_status_cache_key}"
  end

  def clear_session_status_cache
    Rails.cache.delete(session_status_cache_key)
    Rails.logger.info "CACHE: Cleared cache for #{session_status_cache_key}"
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
    else
      # Token ada, tapi belum ada validasi di cache. Menunggu scan.
      { 'data' => { 'connected' => false, 'status' => 'pending_validation' } }
    end
  end

  # Method untuk validasi nomor HP LANGSUNG dari callback - no cache needed!
  # ✅ UBAH: Method ini sekarang menulis ke cache
  def validate_callback_phone_number(callback_phone)
    Rails.logger.info "🔍 Validating callback phone number for #{phone_number}"
    Rails.logger.info "  Expected: #{phone_number}"
    Rails.logger.info "  From callback: #{callback_phone}"

    expected_clean = normalize_phone_number(phone_number)
    callback_clean = normalize_phone_number(self.class.sanitize_phone_number(callback_phone))

    if expected_clean == callback_clean
      Rails.logger.info "✅ Phone validation SUCCESS - numbers match!"

      # ✅ TULIS status 'validated' ke cache
      write_session_status_to_cache('validated')

      {
        success: true,
        status: 'validated',
        message: 'Phone number validation successful'
      }
    else
      Rails.logger.error "❌ Phone validation FAILED - phone mismatch detected"

      write_session_status_to_cache('mismatch', expires_in: 10.minutes)

      # PENTING: Logout session
      logout_result = disconnect_waha_session

      controller = Waha::CallbackController.new
      controller.send(:broadcast_session_mismatch, self, callback_phone)

      # Return failure response
      {
        success: false,
        status: 'mismatch',
        message: 'Phone number mismatch - session logged out',
        expected_phone: phone_number,
        connected_phone: callback_phone,
        logout_result: logout_result
      }
    end
  end

  def waha_configured?
    phone_number.present? && token.present?
  end

  def set_webhook_url
    # Generate webhook URL untuk channel ini
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
      validation_result = validate_callback_phone_number(connected_phone)
      
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
        return { 
          type: 'initial_scan', 
          action: 'validate_failure', 
          data: validation_result.merge({
            session_id: callback_params[:sessionID]
          })
        }
      end
      
    else
      # Unknown callback type
      Rails.logger.info '� Unknown callback type: #{event_type} - processing normally'
      return { type: 'unknown', action: 'process_normally' }
    end
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
