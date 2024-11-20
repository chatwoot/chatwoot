class CalEventUpdateJob < ApplicationJob
  queue_as :default

  def perform(user_id, events)
    user = User.find(user_id)

    # Ensure 'cal_events' is initialized
    user.custom_attributes ||= {}
    user.custom_attributes['cal_events'] ||= {}

    events.each do |event|
      user.custom_attributes['cal_events'].each_key do |account_id|
        add_or_update_cal_event_to_user(user, account_id, event)
      end
    end

    # Save the user with updated cal_events
    user.save
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
