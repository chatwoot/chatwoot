class Notification::FcmService
  SCOPES = ['https://www.googleapis.com/auth/firebase.messaging'].freeze
  TOKEN_MARGIN_SECONDS = 60

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

  # One token per credentials for as long as it is valid, shared across processes
  def cached_token_info
    cached = Rails.cache.read(cache_key)
    return cached if cached && Time.zone.now < cached[:expires_at] - TOKEN_MARGIN_SECONDS

    info = generate_token
    ttl = [info[:expires_at] - Time.zone.now - TOKEN_MARGIN_SECONDS, TOKEN_MARGIN_SECONDS].max
    Rails.cache.write(cache_key, info, expires_in: ttl)
    info
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
    token = authorizer.fetch_access_token!
    {
      token: token['access_token'],
      expires_at: Time.zone.now + token['expires_in'].to_i
    }
  end

  def credentials_path
    StringIO.new(@credentials)
  end
end
