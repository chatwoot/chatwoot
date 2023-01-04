class AddMsOauthTokenToChannel < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_email, :provider_config, :jsonb, default: {}
    add_column :channel_email, :provider, :string
  end
end
