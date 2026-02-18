class X::RefreshTokensJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    # Find channels with tokens expiring in next hour
    expiring_soon = Channel::X
                    .where('token_expires_at < ?', 1.hour.from_now)
                    .where('token_expires_at > ?', Time.current)

    expiring_soon.find_each do |channel|
      X::TokenService.new(channel: channel).refresh_access_token
    rescue StandardError => e
      Rails.logger.error("Failed to refresh X channel #{channel.id} token: #{e.message}")
    end
  end
end
