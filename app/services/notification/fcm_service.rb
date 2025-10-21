class Notification::FcmService
  SCOPES = ['https://www.googleapis.com/auth/firebase.messaging'].freeze

  def initialize(project_id, credentials)
    @project_id = project_id
    @credentials = credentials
    @token_info = nil
  end

  def fcm_client
    FCM.new(current_token, credentials_path, @project_id)
  end

  private

  def current_token
    @token_info = generate_token if @token_info.nil? || token_expired?
    @token_info[:token]
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
