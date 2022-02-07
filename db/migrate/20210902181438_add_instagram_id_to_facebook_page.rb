class AddInstagramIdToFacebookPage < ActiveRecord::Migration[6.1]
  def up
    add_column :channel_facebook_pages, :instagram_id, :string
  end

  def down
    remove_column :channel_facebook_pages, :instagram_id, :string
  end
end
