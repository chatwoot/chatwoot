# Delete migration and spec after 2 consecutive releases.
class Migration::RemoveStaleNotificationsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    remove_conversation_notifications
    remove_message_notifications
  end

  private

  def remove_conversation_notifications
    deleted_ids = []
    Notification.where(primary_actor_type: 'Conversation').pluck(:primary_actor_id).uniq.each_slice(1000) do |id_list|
      deleted_ids << id_list - Conversation.where(id: id_list).pluck(:id)
    end
    Notification.where(primary_actor_type: 'Conversation', primary_actor_id: deleted_ids).destroy_all
  end

  def remove_message_notifications
    deleted_ids = []
    Notification.where(primary_actor_type: 'Message').pluck(:primary_actor_id).uniq.each_slice(1000) do |id_list|
      deleted_ids << id_list - Message.where(id: id_list).pluck(:id)
    end
    Notification.where(primary_actor_type: 'Message', primary_actor_id: deleted_ids).destroy_all
  end
end
