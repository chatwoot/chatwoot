class CreateChannelTwitterProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :channel_twitter_profiles do |t|
      t.string :name
      t.string :profile_id, null: false
      t.string :twitter_access_token, null: false
      t.string :twitter_access_token_secret, null: false
      t.integer :account_id, null: false
      t.timestamps
    end
  end
end
