class Notification::DeleteNotificationJob < ApplicationJob
  queue_as :low

  def perform(user, type: :all)
    ActiveRecord::Base.transaction do
      if type == :all
        # Delete all notifications
        user.notifications.destroy_all
      elsif type == :read
        # Delete only read notifications
        user.notifications.where.not(read_at: nil).destroy_all
      end
    end
  end
end
