# Delete migration and spec after 2 consecutive releases.
class Migration::RemoveStaleNotificationsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    remove_invalid_messages
  end

  private

  def remove_invalid_messages
    deleted_ids = []

    Message.unscoped.distinct.pluck(:inbox_id).each_slice(1000) do |id_list|
      deleted_ids = (id_list - Inbox.where(id: id_list).pluck(:id))
      Message.where(inbox_id: deleted_ids.flatten).destroy_all
    end
  end
end
