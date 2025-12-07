class Whatsapp::InstanceProvisioningService
  class NoPortsAvailableError < StandardError; end
  class ProvisioningTimeoutError < StandardError; end

  def initialize(account)
    @account = account
    @admin_client = Whatsapp::AdminApiClient.new(account)
  end

  def provision(phone_number:, webhook_secret:)
    Rails.logger.info "[WHATSAPP] Starting instance provisioning for #{phone_number}"

    port = find_available_port
    raise NoPortsAvailableError, 'No available ports in configured range' if port.nil?

    basic_auth = generate_basic_auth
    webhook_url = build_webhook_url(phone_number)

    Rails.logger.info "[WHATSAPP] Creating instance on port #{port} with webhook #{webhook_url}"

    @admin_client.create_instance(
      port: port,
      webhook: webhook_url,
      webhook_secret: webhook_secret,
      basic_auth: basic_auth[:combined]
    )

    wait_for_running(port)

    gateway_base_url = build_gateway_url(port)

    Rails.logger.info "[WHATSAPP] Successfully provisioned instance at #{gateway_base_url}"

    {
      gateway_base_url: gateway_base_url,
      port: port,
      basic_auth_user: basic_auth[:user],
      basic_auth_password: basic_auth[:password],
      webhook_url: webhook_url,
      webhook_secret: webhook_secret
    }
  rescue Whatsapp::AdminApiClient::AdminApiError => e
    Rails.logger.error "[WHATSAPP] Provisioning failed: #{e.message}"
    raise
  end

  private

  def find_available_port
    existing = @admin_client.list_instances
    used_ports = existing.is_a?(Array) ? existing.pluck('port') : []

    range_start = @account.whatsapp_admin_port_range_start || 3001
    range_end = @account.whatsapp_admin_port_range_end || 3100

    Rails.logger.debug { "[WHATSAPP] Searching for available port in range #{range_start}..#{range_end}, used ports: #{used_ports}" }

    (range_start..range_end).find { |p| used_ports.exclude?(p) }
  end

  def generate_basic_auth
    user = SecureRandom.alphanumeric(8)
    password = SecureRandom.alphanumeric(16)
    { user: user, password: password, combined: "#{user}:#{password}" }
  end

  def build_webhook_url(phone_number)
    base = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    "#{base}/webhooks/whatsapp_web/#{phone_number}"
  end

  def build_gateway_url(port)
    base_url = @account.whatsapp_admin_api_base_url.chomp('/')
    # Extract host from Admin API URL and use same for gateway
    uri = URI.parse(base_url)
    "#{uri.scheme}://#{uri.host}:#{port}"
  end

  def wait_for_running(port, timeout: 30, interval: 2)
    Rails.logger.info "[WHATSAPP] Waiting for instance on port #{port} to become RUNNING"
    start_time = Time.current
    max_time = start_time + timeout.seconds

    loop do
      instance = @admin_client.get_instance(port)

      if instance['state'] == 'RUNNING'
        Rails.logger.info "[WHATSAPP] Instance on port #{port} is now RUNNING"
        return true
      end

      if Time.current >= max_time
        raise ProvisioningTimeoutError, "Instance did not reach RUNNING state within #{timeout} seconds (current state: #{instance['state']})"
      end

      Rails.logger.debug { "[WHATSAPP] Instance state: #{instance['state']}, waiting..." }
      sleep(interval)
    end
  end
end
