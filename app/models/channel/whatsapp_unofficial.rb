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

  validates :phone_number, presence: true
  validates :account_id, presence: true
  validates :webhook_url, length: { maximum: Limits::URL_LENGTH_LIMIT }

  belongs_to :account
  has_one :inbox, as: :channel, dependent: :destroy

  def name
    'WhatsApp (Unofficial)'
  end

  def send_message(to:, message:, url: nil)
    Fonnte::FonnteService.new.send_message(to: to, message: message, token: token, url: url)
  end

  def set_token
    device_token = Fonnte::FonnteService.new.device_token(phone_number)
    update!(token: device_token) if device_token
  end

  # Method untuk mendapatkan QR code (dipanggil dari WhatsappUnofficialChannelsController)
  def qr_code
    # Implementasi untuk mendapatkan QR code dari WAHA service
    if token.blank?
      Rails.logger.error "Cannot get QR code for phone #{phone_number}: token is blank"
      return nil
    end

    begin
      Rails.logger.info "Requesting QR code from WAHA for phone #{phone_number}"
      
      # Menggunakan WAHA service yang ada di /app/services/waha/waha_service.rb
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
    # Implementasi untuk InboxesController
    # Format return harus { 'data' => { 'qr' => 'base64_qr_code' } } untuk konsistensi
    Rails.logger.info "Getting QR code for phone #{phone_number}, token present: #{token.present?}"
    
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

  # Method untuk mengecek status session
  def session_status
    # Return format yang diharapkan InboxesController: { 'data' => { 'connected' => true/false, 'status' => 'status_string' } }
    unless waha_configured?
      return {
        'data' => {
          'connected' => false,
          'status' => 'disconnected'
        }
      }
    end
    
    fetch_session_status_from_waha
  end

  def waha_configured?
    phone_number.present? && token.present?
  end

  def set_webhook_url
    # Generate webhook URL untuk channel ini
    base_url = current_application_url
    webhook = "#{base_url}/api/v1/waha/callback/#{phone_number}"
    
    update!(webhook_url: webhook)
    Rails.logger.info "Webhook URL set for phone #{phone_number}: #{webhook}"
    webhook
  rescue StandardError => e
    Rails.logger.error "Failed to set webhook URL for phone #{phone_number}: #{e.message}"
    # Set default webhook URL sebagai fallback
    fallback_webhook = "#{current_application_url}/api/v1/waha/callback/#{phone_number}"
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
    waha_service = Waha::WahaService.instance
    result = waha_service.get_session_status(api_key: token)
    
    build_session_status_response(result)
  rescue StandardError => e
    Rails.logger.error "Failed to get session status for #{phone_number}: #{e.message}"
    error_session_status
  end

  def build_session_status_response(result)
    if result.present?
      # WAHA sekarang mengembalikan 'status' langsung di data
      session_status = result.dig('data', 'status') || result['status'] || default_status
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
