class Notification::FcmService
  SCOPES = ['https://www.googleapis.com/auth/firebase.messaging'].freeze
  TOKEN_MARGIN_SECONDS = 60
  # Access tokens stay in process memory.
  TOKENS = {} # rubocop:disable Style/MutableConstant
  TOKENS_LOCK = Mutex.new
  TOKEN_REQUEST_TIMEOUT_SECONDS = 10
  # Includes the auth library's retries.
  TOKEN_REFRESH_BUDGET_SECONDS = 15
  TOKEN_RETRY_SECONDS = 30

  class TokenUnavailable < StandardError; end

  def initialize(project_id, credentials)
    @project_id = project_id
    @credentials = credentials
    @token_info = nil
  end

  # The FCM client otherwise fetches a token for every send.
  def fcm_client
    token = current_token
    client = FCM.new(token, credentials_path, @project_id)
    client.define_singleton_method(:jwt_token) { token }
    client
  end

  private

  def current_token
    @token_info = cached_token_info if @token_info.nil? || token_expired?
    @token_info[:token]
  end

  def cached_token_info
    TOKENS_LOCK.synchronize do
      cached = TOKENS[cache_key] || {}
      return cached if before?(cached[:expires_at], TOKEN_MARGIN_SECONDS)
      raise TokenUnavailable, 'Google token request failed recently' if before?(cached[:failed_until])

      TOKENS[cache_key] = generate_token
    rescue StandardError => e
      TOKENS[cache_key] = { failed_until: Time.zone.now + TOKEN_RETRY_SECONDS } unless e.is_a?(TokenUnavailable)
      raise
    end
  end

  def before?(time, margin = 0)
    time.present? && Time.zone.now < time - margin
  end

  def cache_key
    "fcm_access_token:#{@project_id}:#{Digest::SHA256.hexdigest(@credentials.to_s)[0, 12]}"
  end

  def token_expired?
    Time.zone.now >= @token_info[:expires_at]
  end

  def generate_token
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: credentials_path,
      scope: SCOPES
    )
    token = Timeout.timeout(TOKEN_REFRESH_BUDGET_SECONDS) { authorizer.fetch_access_token!(connection: token_connection) }
    {
      token: token['access_token'],
      expires_at: Time.zone.now + token['expires_in'].to_i
    }
  end

  def token_connection
    Faraday.new(request: { timeout: TOKEN_REQUEST_TIMEOUT_SECONDS, open_timeout: TOKEN_REQUEST_TIMEOUT_SECONDS })
  end

  def credentials_path
    StringIO.new(@credentials)
  end
end
