class ChatwootCaptcha
  def initialize(client_response)
    @client_response = client_response
    @server_key = GlobalConfigService.load('HCAPTCHA_SERVER_KEY', '')
  end

  def valid?
    return true if @server_key.blank?
    return false if @client_response.blank?

    validate_client_response?
  end

  def validate_client_response?
    response = HTTParty.post('https://hcaptcha.com/siteverify',
                             body: {
                               response: @client_response,
                               secret: @server_key
                             })

    return false unless response.success?

    response.parsed_response['success']
  end
end
