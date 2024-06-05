class FCMService
  SCOPES = ['https://www.googleapis.com/auth/firebase.messaging'].freeze

  def initialize(credentials_path, project_id)
    @credentials_path = credentials_path
    @project_id = project_id
    @token_info = nil
  end

  def fcm_client
    FCM.new(current_token, @credentials_path, @project_id)
  end

  private

  def current_token
    @token_info = generate_token if @token_info.nil? || token_expired?
    @token_info[:token]
  end

  def token_expired?
    Time.now >= @token_info[:expires_at]
  end

  def generate_token
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(@credentials_path),
      scope: SCOPES
    )
    token = authorizer.fetch_access_token!
    {
      token: token['access_token'],
      expires_at: Time.now + token['expires_in'].to_i
    }
  end
end
