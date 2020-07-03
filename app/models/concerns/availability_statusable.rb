module AvailabilityStatusable
  extend ActiveSupport::Concern

  def online_presence?
    ::OnlineStatusTracker.get_presence(availability_account_id, self.class.name, id)
  end

  def availability_status
    return 'offline' unless online_presence?
    return 'online' if is_a? Contact

    ::OnlineStatusTracker.get_status(availability_account_id, id) || 'online'
  end

  def availability_account_id
    return account_id if is_a? Contact

    Current.account.present? ? Current.account.id : accounts.first.id
  end
end
