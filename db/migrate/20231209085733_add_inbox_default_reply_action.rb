class AddInboxDefaultReplyAction < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :default_reply_action, :string
    add_column :accounts, :csat_trigger, :string
  end
end
