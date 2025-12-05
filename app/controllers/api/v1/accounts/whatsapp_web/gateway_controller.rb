class Api::V1::Accounts::WhatsappWeb::GatewayController < Api::V1::Accounts::BaseController
  before_action :set_inbox, except: [:test_connection, :test_devices]
  before_action :ensure_whatsapp_web_channel, except: [:test_connection, :test_devices]

  # POST /api/v1/accounts/:account_id/whatsapp_web/gateway/test_connection
  def test_connection
    Rails.logger.info '[WHATSAPP_WEB] Test connection endpoint called'

    # Extract gateway config from request parameters
    gateway_base_url = params[:gateway_base_url]
    basic_auth_user = params[:basic_auth_user]
    basic_auth_password = params[:basic_auth_password]
    phone_number = params[:phone_number] || '+5521987654321' # Default for testing

    if gateway_base_url.blank?
      render json: { success: false, error: 'Gateway base URL is required' }, status: :bad_request
      return
    end

    # Create a temporary service for testing
    temp_service = create_temp_service(gateway_base_url, basic_auth_user, basic_auth_password, phone_number)
    result = temp_service.test_connection_with_qr_conversion

    render json: { success: true, data: result }
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_WEB] Test connection error: #{e.message}"
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/accounts/:account_id/whatsapp_web/gateway/test_devices
  def test_devices
    Rails.logger.info '[WHATSAPP_WEB] Test devices endpoint called'

    # Extract gateway config from request parameters
    gateway_base_url = params[:gateway_base_url]
    basic_auth_user = params[:basic_auth_user]
    basic_auth_password = params[:basic_auth_password]
    phone_number = params[:phone_number] || '+5521987654321' # Default for testing

    if gateway_base_url.blank?
      render json: { success: false, error: 'Gateway base URL is required' }, status: :bad_request
      return
    end

    # Create a temporary service for testing
    temp_service = create_temp_service(gateway_base_url, basic_auth_user, basic_auth_password, phone_number)
    result = temp_service.gateway_devices

    render json: { success: true, data: result }
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_WEB] Test devices error: #{e.message}"
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/whatsapp_web/gateway/:id/login
  def login
    Rails.logger.info "[WHATSAPP_WEB] Login endpoint called for inbox #{params[:id]}"
    result = @gateway_service.connect_with_qr_conversion
    Rails.logger.info "[WHATSAPP_WEB] Gateway response: #{result}"

    render json: { success: true, data: result }
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_WEB] Login error: #{e.message}"
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/whatsapp_web/gateway/:id/login_with_code
  def login_with_code
    phone = params[:phone]
    result = @gateway_service.gateway_login_with_code(phone)
    render json: { success: true, data: result }
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/whatsapp_web/gateway/:id/status
  def status
    result = @gateway_service.connection_status
    render json: { success: true, data: result }
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/whatsapp_web/gateway/:id/devices
  def devices
    result = @gateway_service.gateway_devices
    render json: { success: true, data: result }
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/whatsapp_web/gateway/:id/logout
  def logout
    result = @gateway_service.gateway_logout
    render json: { success: true, data: result }
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/whatsapp_web/gateway/:id/reconnect
  def reconnect
    result = @gateway_service.gateway_reconnect
    render json: { success: true, data: result }
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/accounts/:account_id/whatsapp_web/gateway/:id/sync_history
  def sync_history
    Rails.logger.info "[WHATSAPP_WEB] Manual history sync requested for inbox #{@inbox.id}"

    # Trigger manual history sync - bypasses the 'already done' check
    Whatsapp::HistorySyncApiJob.perform_later(@inbox.id, manual: true)

    render json: {
      success: true,
      message: 'History sync initiated successfully',
      inbox_id: @inbox.id
    }
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_WEB] History sync initiation error: #{e.message}"
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/whatsapp_web/gateway/:id/qr_code?path=<path>
  def qr_code
    qr_path = params[:path]

    if qr_path.blank?
      render json: { error: 'QR code path is required' }, status: :bad_request
      return
    end

    # Proxy the QR code image from the gateway
    result = @gateway_service.proxy_qr_code(qr_path)

    if result[:success]
      send_data result[:data],
                type: result[:content_type],
                disposition: 'inline',
                filename: 'qr-code.png'
    else
      render json: { error: result[:error] }, status: :not_found
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_WEB] QR code proxy error: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def set_inbox
    @inbox = Current.account.inboxes.find(params[:id])
    @gateway_service = Whatsapp::Providers::WhatsappWebService.new(
      whatsapp_channel: @inbox.channel
    )
  end

  def ensure_whatsapp_web_channel
    return if @inbox&.channel&.provider == 'whatsapp_web'

    render json: { error: 'Inbox must be a WhatsApp Web channel' }, status: :bad_request
  end

  def gateway_params
    params.permit(:id, :inbox_id, :phone, :path, :gateway_base_url, :basic_auth_user, :basic_auth_password, :phone_number)
  end

  def create_temp_service(gateway_base_url, basic_auth_user, basic_auth_password, phone_number)
    temp_config = {
      'gateway_base_url' => gateway_base_url,
      'basic_auth_user' => basic_auth_user,
      'basic_auth_password' => basic_auth_password
    }

    temp_channel = OpenStruct.new(
      provider_config: temp_config,
      phone_number: phone_number
    )

    Whatsapp::Providers::WhatsappWebService.new(
      whatsapp_channel: temp_channel
    )
  end
end
