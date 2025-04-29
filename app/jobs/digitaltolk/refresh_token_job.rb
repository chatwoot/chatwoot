class Digitaltolk::RefreshTokenJob < ApplicationJob
  queue_as :low

  def perform(user_auth)
    return unless user_auth

    user_auth.perform_refresh_token!
  end
end
