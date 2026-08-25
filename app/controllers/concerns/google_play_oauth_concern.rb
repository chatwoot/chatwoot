module GooglePlayOauthConcern
  extend ActiveSupport::Concern
  include GoogleConcern

  GOOGLE_PLAY_SCOPE = 'https://www.googleapis.com/auth/androidpublisher'.freeze

  private

  # Overrides the Gmail scope from GoogleConcern with the Play Developer API scope
  def scope
    GOOGLE_PLAY_SCOPE
  end

  # Carries the account and channel details through the OAuth round trip
  def google_play_verifier
    Rails.application.message_verifier('google_play_oauth')
  end

  def google_play_callback_url
    "#{base_url}/google_play/callback"
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
