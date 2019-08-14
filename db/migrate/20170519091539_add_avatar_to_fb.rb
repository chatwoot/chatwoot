class AddAvatarToFb < ActiveRecord::Migration[5.0]
  def change
    remove_column :inboxes, :avatar
    add_column :facebook_pages, :avatar, :string, default: nil
  end
end
