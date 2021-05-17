class MigrationRemoveLockedFromConversation < ActiveRecord::Migration[6.0]
  def change
    remove_column :conversations, :locked, :boolean
  end
end
