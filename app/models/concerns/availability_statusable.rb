module AvailabilityStatusable
  extend ActiveSupport::Concern

  def online_presence?
    return if user_profile_page_context?

    ::OnlineStatusTracker.get_presence(availability_account_id, self.class.name, id)
  end

  def availability_status
    return availability if user_profile_page_context?
    return 'offline' unless online_presence?
    return 'online' if is_a? Contact

    ::OnlineStatusTracker.get_status(availability_account_id, id) || 'online'
  end

  def user_profile_page_context?
    # at the moment profile pages aren't account scoped
    # hence we will return availability attribute instead of true presence
    # we will revisit this later
    is_a?(User) && Current.account.blank?
  end

  def availability_account_id
    return account_id if is_a? Contact

    Current.account.id
  end
end
