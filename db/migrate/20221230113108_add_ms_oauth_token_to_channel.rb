class AddMsOauthTokenToChannel < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_email, :ms_oauth_token_hash, :jsonb
  end
end
