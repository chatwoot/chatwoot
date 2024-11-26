class CalEventDestroyJob < ApplicationJob
  queue_as :default

  def perform(user_id, uid)
    user = User.find(user_id)

    user.custom_attributes ||= {}
    user.custom_attributes['cal_events'] ||= {}

    user.custom_attributes['cal_events'].transform_values! do |cal_events|
      cal_events.reject { |event| event['uid'] == uid }
    end

    user.save
  end
end
