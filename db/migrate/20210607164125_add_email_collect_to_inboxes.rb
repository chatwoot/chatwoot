class AddEmailCollectToInboxes < ActiveRecord::Migration[6.0]
  def change
    add_column :inboxes, :enable_email_collect, :boolean, default: true
  end
end
