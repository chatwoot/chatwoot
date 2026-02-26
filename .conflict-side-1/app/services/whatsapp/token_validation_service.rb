class Whatsapp::TokenValidationService
  def initialize(access_token, waba_id)
    @access_token = access_token
    @waba_id = waba_id
    @api_client = Whatsapp::FacebookApiClient.new(access_token)
  end

  def perform
    validate_parameters!
    validate_token_waba_access
  end

  private

  def validate_parameters!
    raise ArgumentError, 'Access token is required' if @access_token.blank?
    raise ArgumentError, 'WABA ID is required' if @waba_id.blank?
  end

  def validate_token_waba_access
    token_debug_data = @api_client.debug_token(@access_token)
    waba_scope = extract_waba_scope(token_debug_data)
    verify_waba_authorization(waba_scope)
  end

  def extract_waba_scope(token_data)
    granular_scopes = token_data.dig('data', 'granular_scopes')
    waba_scope = granular_scopes&.find { |scope| scope['scope'] == 'whatsapp_business_management' }

    raise 'No WABA scope found in token' unless waba_scope

    waba_scope
  end

  def verify_waba_authorization(waba_scope)
    authorized_waba_ids = waba_scope['target_ids'] || []

    return if authorized_waba_ids.include?(@waba_id)

    raise "Token does not have access to WABA #{@waba_id}. Authorized WABAs: #{authorized_waba_ids}"
  end
end
