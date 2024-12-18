class CalEventDestroyJob < ApplicationJob
  queue_as :default

  def perform(account_user_ids, uids)
    uids_set = Set.new(uids.map(&:to_i))
    account_user_ids = account_user_ids.map(&:to_i)

    account_users = AccountUser.includes(:user).where(id: account_user_ids)
    users = account_users.map(&:user).uniq
    users.each do |user|
      user.custom_attributes ||= {}
      user.custom_attributes['cal_events'] ||= {}

      user.custom_attributes['cal_events'].transform_values! do |cal_events|
        cal_events.reject { |event| uids_set.include?(event['uid']) }
      end

      user.save
    end
  end
end
