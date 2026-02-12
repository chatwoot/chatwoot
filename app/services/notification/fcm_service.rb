class Notification::FcmService
  SCOPES = ['https://www.googleapis.com/auth/firebase.messaging'].freeze

  def initialize(project_id, credentials)
    @project_id = project_id
    @credentials = credentials
    @token_info = nil
  end

  def fcm_client
    FCM.new(credentials_path, @project_id)
  end

  private

  def credentials_path
    StringIO.new(@credentials)
  end
end
