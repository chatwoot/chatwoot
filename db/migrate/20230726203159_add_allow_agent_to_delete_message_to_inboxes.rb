class AddAllowAgentToDeleteMessageToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :allow_agent_to_delete_message, :boolean, default: true, null: false
  end
end
