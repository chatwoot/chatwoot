class Instagram::UserDetailsService
  class Error < StandardError
    attr_reader :http_status

    def initialize(message, http_status)
      @http_status = http_status
      super(message)
    end
  end

  pattr_initialize [:access_token!]

  def perform
    response = HTTParty.get(
      "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}/me",
      query: {
        fields: 'id,username,user_id,name,profile_picture_url,account_type',
        access_token: access_token
      },
      headers: { 'Accept' => 'application/json' }
    )

    unless response.success?
      Rails.logger.error "Failed to fetch Instagram user details. Status: #{response.code}, Body: #{response.body}"
      raise Error.new("Failed to fetch Instagram user details: #{response.body}", response.code)
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    ChatwootExceptionTracker.new(e).capture_exception
    Rails.logger.error "Invalid JSON response: #{response.body}"
    raise
  end
end
