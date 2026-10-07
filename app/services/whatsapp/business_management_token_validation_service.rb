class Whatsapp::BusinessManagementTokenValidationService
  REQUIRED_PERMISSION = 'whatsapp_business_management'.freeze

  def initialize(business_management_token, business_account_id)
    @business_management_token = business_management_token
    @business_account_id = business_account_id
  end

  def perform
    response = HTTParty.get(permissions_url, headers: { 'Authorization' => "Bearer #{@business_management_token}" })

    raise ArgumentError, response_error(response) unless response.success?
    raise ArgumentError, "Business management token must grant the #{REQUIRED_PERMISSION} permission" unless required_permission_granted?(response)

    validate_business_account_access!
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError
    raise ArgumentError, 'Could not validate business management token permissions. Please try again.'
  end

  private

  def permissions_url
    base_path = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
    api_version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
    "#{base_path}/#{api_version}/me/permissions"
  end

  def business_account_templates_url
    base_path = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
    api_version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
    "#{base_path}/#{api_version}/#{@business_account_id}/message_templates?limit=1"
  end

  def required_permission_granted?(response)
    permissions = response.parsed_response.is_a?(Hash) ? response.parsed_response['data'] : []
    Array(permissions).select { |permission| permission.is_a?(Hash) }
                      .any? { |permission| permission['permission'] == REQUIRED_PERMISSION && permission['status'] == 'granted' }
  end

  def validate_business_account_access!
    response = HTTParty.get(
      business_account_templates_url,
      headers: { 'Authorization' => "Bearer #{@business_management_token}" }
    )

    raise ArgumentError, response_error(response) unless response.success?

    true
  end

  def response_error(response)
    error_message = response.parsed_response.is_a?(Hash) ? response.parsed_response.dig('error', 'message') : nil
    error_message.presence || 'Could not validate business management token permissions'
  end
end
