module AvailabilityStatusable
  extend ActiveSupport::Concern

  def online_presence?
    ::OnlineStatusTracker.update_presence(pubsub_token)
  end

  def availability_status
    return online_presence? ? 'online' : 'offline' if is_a? Contact
    return 'offline' unless online_presence?

    ::OnlineStatusTracker.get_status(pubsub_token)
  end
end
