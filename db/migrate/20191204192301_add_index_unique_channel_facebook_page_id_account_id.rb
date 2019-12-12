class AddIndexUniqueChannelFacebookPageIdAccountId < ActiveRecord::Migration[6.0]
  def change
    add_index :channel_facebook_pages, [:page_id, :account_id], unique: true
  end
end
