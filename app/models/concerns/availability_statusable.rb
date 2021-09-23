module AvailabilityStatusable
  extend ActiveSupport::Concern

  def online_presence?
    obj_id = self.is_a?(Contact) ? self.id : self.user_id
    ::OnlineStatusTracker.get_presence(account_id, self.class.name, obj_id)
  end

  def availability_status
    return availability  if self.is_a?(AccountUser) && !auto_offline
    return 'offline' unless online_presence?
    return 'online' if is_a? Contact

    ::OnlineStatusTracker.get_status(account_id, user_id) || availability
  end
end
