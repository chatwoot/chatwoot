module AvailabilityStatusable
  extend ActiveSupport::Concern

  def online?
    ::OnlineStatusTracker.subscription_count(pubsub_token) != 0
  end

  def availability_status
    online? ? 'online' : 'offline'
  end
end
