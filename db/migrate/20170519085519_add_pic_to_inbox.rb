class AddPicToInbox < ActiveRecord::Migration[5.0]
  def change
    add_column :inboxes, :avatar, :string, default: nil
  end
end
