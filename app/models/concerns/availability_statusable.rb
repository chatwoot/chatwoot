module AvailabilityStatusable
  extend ActiveSupport::Concern

  def online_presence?
    obj_id = is_a?(Contact) ? id : user_id
    ::OnlineStatusTracker.get_presence(account_id, self.class.name, obj_id)
  end

  def availability_status
    if is_a? Contact
      contact_availability_status
    else
      user_availability_status
    end
  end

  private

  def contact_availability_status
    online_presence? ? 'online' : 'offline'
  end

  def user_availability_status
    # we are not considering presence in this case. Just returns the availability
    return availability unless auto_offline

    # availability as a fallback in case the status is not present in redis
    online_presence? ? (::OnlineStatusTracker.get_status(account_id, user_id) || availability) : 'offline'
  end
end
