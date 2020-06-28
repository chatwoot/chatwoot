module AvailabilityStatusable
  extend ActiveSupport::Concern

  def online_presence?
    ::OnlineStatusTracker.get_presence(pubsub_token)
  end

  def availability_status
    return 'offline' unless online_presence?
    return contact_online_status if is_a? Contact

    ::OnlineStatusTracker.get_status(pubsub_token) || 'online'
  end

  def contact_online_status
    online_presence? ? 'online' : 'offline'
  end
end
