# frozen_string_literal: true

class Dealership::BookingStatsService
  include HTTParty

  class ApiError < StandardError
    attr_reader :code, :response

    def initialize(message = nil, code = nil, response = nil)
      @code = code
      @response = response
      super(message)
    end
  end

  def initialize(dealership_id, period: 'daily', since: nil, until_time: nil)
    @dealership_id = dealership_id
    @period = period
    @since = since
    @until_time = until_time
    # Try GlobalConfig first, fallback to ENV, then default
    @base_uri = GlobalConfig.get('DEALERSHIP_API_BASE_URL')&.[]('DEALERSHIP_API_BASE_URL') ||
                ENV.fetch('DEALERSHIP_API_BASE_URL', 'https://api.example.com')
    @api_key = GlobalConfig.get('DEALERSHIP_API_KEY')&.[]('DEALERSHIP_API_KEY') ||
               ENV.fetch('DEALERSHIP_API_KEY', nil)
  end

  def fetch_stats
    return { data: [], period: @period } if @dealership_id.blank?

    begin
      response = make_request
      parse_response(response)
    rescue ApiError => e
      Rails.logger.error("Dealership API Error (#{e.code}): #{e.message}")
      { data: [], period: @period }
    rescue StandardError => e
      Rails.logger.error("Dealership Stats Service Error: #{e.message}")
      { data: [], period: @period }
    end
  end

  private

  def make_request
    url = "#{@base_uri}/api/v1/dealerships/#{@dealership_id}/stats"
    
    query_params = { period: @period }
    query_params[:since] = @since if @since
    query_params[:until] = @until_time if @until_time
    
    headers = { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
    headers['Authorization'] = "Bearer #{@api_key}" if @api_key.present?
    
    response = self.class.get(url, query: query_params, headers: headers, timeout: 30)
    handle_response(response)
  end

  def handle_response(response)
    case response.code
    when 200..299
      response
    when 404
      raise ApiError.new('Dealership not found', 404, response)
    when 500..599
      raise ApiError.new('Dealership API server error', response.code, response)
    else
      raise ApiError.new("Unexpected response: #{response.code}", response.code, response)
    end
  end

  def parse_response(response)
    body = response.parsed_response
    return { data: [], period: @period } unless body.is_a?(Hash)

    # Handle nested response structures
    nested_data = body.dig('body', 'data', 'data') || body.dig('data', 'data') || body['data']
    
    if nested_data.is_a?(Array)
      period = body.dig('body', 'data', 'period') || body.dig('data', 'period') || body['period'] || @period
      { data: nested_data, period: period }
    else
      { data: [], period: @period }
    end
  rescue JSON::ParserError => e
    raise ApiError.new("Failed to parse response: #{e.message}", response.code, response)
  end
end

