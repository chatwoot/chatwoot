class Notification::DeleteNotificationJob < ApplicationJob
  queue_as :low

  def perform(user, account, type: :all)
    notifications = user.notifications.where(account_id: account.id)

    ActiveRecord::Base.transaction do
      if type == :all
        notifications.destroy_all
      elsif type == :read
        notifications.where.not(read_at: nil).destroy_all
      end
    end
  end
end
