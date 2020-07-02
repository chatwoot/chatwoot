module AvailabilityStatusable
  extend ActiveSupport::Concern

  def online_presence?
    if is_a? Contact
      ::OnlineStatusTracker.get_presence(account_id, 'Contact', id)
    else
      ::OnlineStatusTracker.get_presence(Current.account.id, 'User', id)
    end
  end

  def availability_status
    return 'offline' unless online_presence?
    return 'online' if is_a? Contact

    ::OnlineStatusTracker.get_status(Current.account.id, id) || 'online'
  end
end
