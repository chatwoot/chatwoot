class InfluencersClub::Client
  include HTTParty

  BASE_URI = 'https://api-dashboard.influencers.club'.freeze

  class ApiError < StandardError
    attr_reader :code, :response

    def initialize(message = nil, code = nil, response = nil)
      @code = code
      @response = response
      super(message)
    end
  end

  def initialize(jwt_token: ENV.fetch('INFLUENCERS_CLUB_JWT_TOKEN'))
    @jwt_token = jwt_token
  end

  def post(path, body = {})
    url = "#{BASE_URI}#{path}"
    response = self.class.post(url, headers: headers, body: body.to_json)
    handle_response(response)
  end

  private

  def headers
    {
      'Authorization' => "Bearer #{@jwt_token}",
      'Content-Type' => 'application/json'
    }
  end

  def handle_response(response)
    case response.code
    when 200..299
      response.parsed_response
    when 429
      raise ApiError.new('influencers.club rate limit exceeded', response.code, response)
    else
      error_message = "influencers.club API error: #{response.code} - #{response.body}"
      Rails.logger.error error_message
      raise ApiError.new(error_message, response.code, response)
    end
  end
end
