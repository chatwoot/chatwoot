class AddAiAutoReplyToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :ai_auto_reply, :boolean, null: false, default: false
  end
end
