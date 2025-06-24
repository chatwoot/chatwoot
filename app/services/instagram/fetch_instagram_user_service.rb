class Instagram::FetchInstagramUserService
  def initialize(inbox_id, ig_scope_id)
    @ig_scope_id = ig_scope_id
    @inbox = Inbox.find(inbox_id)
  end

  def perform
    url = "#{base_uri}/#{@ig_scope_id}"
    fields = 'name,username,profile_pic,follower_count,is_user_follow_business,is_business_follow_user,is_verified_user'

    response = HTTParty.get(url, query: {
                              fields: fields,
                              access_token: @inbox.channel.access_token
                            })

    return process_successful_response(response) if response.success?

    handle_error_response(response)
    {}
  end

  private

  def process_successful_response(response)
    keys = %w[name username profile_pic id follower_count is_user_follow_business is_business_follow_user is_verified_user]
    result = JSON.parse(response.body).with_indifferent_access
    result.slice(*keys).with_indifferent_access
  end

  def handle_error_response(response)
    parsed_response = response.parsed_response
    error_message = parsed_response.dig('error', 'message')
    error_code = parsed_response.dig('error', 'code')

    # https://developers.facebook.com/docs/messenger-platform/error-codes
    # Access token has expired or become invalid.
    channel.authorization_error! if error_code == 190

    Rails.logger.warn("[InstagramUserFetchError]: account_id #{@inbox.account_id} inbox_id #{@inbox.id}")
    Rails.logger.warn("[InstagramUserFetchError]: #{error_message} #{error_code}")

    ChatwootExceptionTracker.new(parsed_response, account: @inbox.account).capture_exception
  end

  def base_uri
    "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"
  end
end
