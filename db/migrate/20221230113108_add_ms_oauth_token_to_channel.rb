class AddMsOauthTokenToChannel < ActiveRecord::Migration[6.1]
  def change
    change_table :channel_email, bulk: true do |t|
      t.jsonb :provider_config, default: {}
      t.string :provider
    end
  end
end
