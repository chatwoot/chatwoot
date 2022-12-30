class AddMsOauthTokenToChannel < ActiveRecord::Migration[6.1]
  def change
    change_table :channel_email, bulk: true do |t|
      t.text :ms_oauth_token
      t.datetime :ms_oauth_token_expires_on
    end
  end
end
