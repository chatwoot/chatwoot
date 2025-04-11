class Crm::Leadsquared::Api::BaseClient
  include HTTParty

  def initialize(access_key, secret_key, endpoint_url)
    @access_key = access_key
    @secret_key = secret_key
    @base_uri = endpoint_url
  end

  def get(path, params = {})
    params = params.merge(auth_params)
    full_url = URI.join(@base_uri, path).to_s

    response = self.class.get(full_url, query: params)
    handle_response(response)
  end

  def post(path, params = {}, body = {})
    params = params.merge(auth_params)
    full_url = URI.join(@base_uri, path).to_s

    options = {
      query: params,
      headers: { 'Content-Type' => 'application/json' }
    }

    options[:body] = body.to_json if body.present?

    response = self.class.post(full_url, options)
    handle_response(response)
  end

  private

  def auth_params
    {
      accessKey: @access_key,
      secretKey: @secret_key
    }
  end

  def handle_response(response)
    case response.code
    when 200..299
      begin
        body = response.parsed_response

        if body.is_a?(Hash) && body['Status'] == 'Error'
          Rails.logger.error "LeadSquared API error: #{body['ExceptionMessage']}"
          { success: false, error: body['ExceptionMessage'], code: response.code }
        else
          { success: true, data: body }
        end
      rescue StandardError => e
        Rails.logger.error "Failed to parse LeadSquared API response: #{e.message}"
        { success: false, error: 'Invalid response', code: response.code }
      end
    else
      Rails.logger.error "LeadSquared API error: #{response.code} - #{response.body}"
      { success: false, error: response.body, code: response.code }
    end
  end
end
