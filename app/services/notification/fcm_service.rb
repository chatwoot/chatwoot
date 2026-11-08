class Notification::FcmService
  SCOPES = ['https://www.googleapis.com/auth/firebase.messaging'].freeze
  TOKEN_MARGIN_SECONDS = 60
  # Google access tokens by credentials, held in this process only
  TOKENS = {} # rubocop:disable Style/MutableConstant
  TOKENS_LOCK = Mutex.new
  # How long a token request to Google may take. Callers for the same credentials wait on
  # it, so it is kept well inside a call's ring.
  TOKEN_REQUEST_TIMEOUT_SECONDS = 10
  # How long a whole token refresh may take, the auth library's own retries included
  TOKEN_REFRESH_BUDGET_SECONDS = 15
  # After a token request fails, callers for the same credentials fail at once for this
  # long instead of each repeating the request in turn
  TOKEN_RETRY_SECONDS = 30

  class TokenUnavailable < StandardError; end

  def initialize(project_id, credentials)
    @project_id = project_id
    @credentials = credentials
    @token_info = nil
  end

  # The client fetches a fresh Google OAuth token on every send, about a second each;
  # it is given the cached token instead
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

  # One token per credentials for as long as it is valid, kept in this process only: the
  # bearer token is never written to a shared or on-disk cache
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

  def before?(time, margin = 0) = time.present? && Time.zone.now < time - margin

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
