class Whatsapp::TokenExchangeService
  def initialize(code)
    @code = code
    @api_client = Whatsapp::FacebookApiClient.new
  end

  def perform
    validate_code!
    exchange_token
  end

  private

  def validate_code!
    raise ArgumentError, 'Authorization code is required' if @code.blank?
  end

  def exchange_token
    response = @api_client.exchange_code_for_token(@code)
    access_token = response['access_token']

    raise "No access token in response: #{response}" if access_token.blank?

    access_token
  end
end
