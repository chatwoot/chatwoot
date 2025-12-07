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

  # GET /api/v1/accounts/:account_id/whatsapp_web/gateway/admin_api_status
  def admin_api_status
    configured = Current.account.whatsapp_admin_api_configured?
    healthy = configured ? Whatsapp::AdminApiClient.healthy?(Current.account) : false

    available_ports = 0
    if configured && healthy
      client = Whatsapp::AdminApiClient.new(Current.account)
      instances = client.list_instances
      used_count = instances.is_a?(Array) ? instances.length : 0
      range_start = Current.account.whatsapp_admin_port_range_start || 3001
      range_end = Current.account.whatsapp_admin_port_range_end || 3100
      available_ports = (range_end - range_start + 1) - used_count
    end

    render json: {
      configured: configured,
      healthy: healthy,
      available_ports: available_ports,
      port_range: {
        start: Current.account.whatsapp_admin_port_range_start || 3001,
        end: Current.account.whatsapp_admin_port_range_end || 3100
      }
    }
  rescue StandardError => e
    render json: { configured: configured, healthy: false, error: e.message }
  end

  # POST /api/v1/accounts/:account_id/whatsapp_web/gateway/provision_instance
  def provision_instance
    phone_number = params[:phone_number]
    webhook_secret = params[:webhook_secret] || SecureRandom.hex(16)

    if phone_number.blank?
      render json: { success: false, error: 'Phone number is required' }, status: :bad_request
      return
    end

    service = Whatsapp::InstanceProvisioningService.new(Current.account)
    result = service.provision(phone_number: phone_number, webhook_secret: webhook_secret)

    render json: { success: true, data: result }
  rescue Whatsapp::AdminApiClient::NotConfiguredError => e
    render json: { success: false, error: e.message }, status: :bad_request
  rescue Whatsapp::InstanceProvisioningService::NoPortsAvailableError => e
    render json: { success: false, error: e.message }, status: :service_unavailable
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Provision instance error: #{e.message}"
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/whatsapp_web/gateway/available_instances
  def available_instances
    client = Whatsapp::AdminApiClient.new(Current.account)
    instances = client.list_instances

    render json: { success: true, data: instances }
  rescue Whatsapp::AdminApiClient::NotConfiguredError => e
    render json: { success: false, error: e.message }, status: :bad_request
  rescue StandardError => e
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
