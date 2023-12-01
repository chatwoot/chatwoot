class RemoveNotificationsWithMessagePrimaryActor < ActiveRecord::Migration[7.0]
  def up
    Notification.where(primary_actor_type: 'Message').in_batches(of: 100).each_record(&:destroy)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
