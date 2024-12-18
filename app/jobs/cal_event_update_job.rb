class CalEventUpdateJob < ApplicationJob
  queue_as :default

  def perform(account_user_ids, events)
    account_users = AccountUser.includes(:user).where(id: account_user_ids)

    # Extract unique users
    users = account_users.map(&:user).uniq

    users.each do |user|
      user.custom_attributes ||= {}
      user.custom_attributes['cal_events'] ||= {}

      events.each do |event|
        user.custom_attributes['cal_events'].each_key do |account_id|
          add_or_update_cal_event_to_user(user, account_id, event)
        end
      end

      user.save
    end
  end

  private

  def add_or_update_cal_event_to_user(user, account_id, event)
    cal_events = user.custom_attributes['cal_events'][account_id] ||= []
    existing_event = cal_events.find { |e| e['uid'] == event['uid'] }

    if existing_event
      existing_event.merge!(event)
    else
      cal_events << event
    end
  end
end
