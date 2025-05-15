class AddLabelToResolveConversation < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :add_label_to_resolve_conversation, :boolean, default: false, null: false
  end
end
