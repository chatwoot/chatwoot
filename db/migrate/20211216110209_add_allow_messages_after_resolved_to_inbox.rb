class AddAllowMessagesAfterResolvedToInbox < ActiveRecord::Migration[6.1]
  def change
    add_column :inboxes, :allow_messages_after_resolved, :boolean, default: true
  end
end
