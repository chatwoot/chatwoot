class RemoveNotificationsWithoutPrimaryActor < ActiveRecord::Migration[6.0]
  def change
    deleted_ids = []
    Notification.where(primary_actor_type: 'Conversation').pluck(:primary_actor_id).uniq.each_slice(1000) do |id_list|
      deleted_ids << (id_list - Conversation.where(id: id_list).pluck(:id))
    end
    Notification.where(primary_actor_type: 'Conversation', primary_actor_id: deleted_ids).destroy_all
  end
end
