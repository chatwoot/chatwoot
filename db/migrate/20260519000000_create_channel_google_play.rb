class CreateChannelGooglePlay < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_google_play do |t|
      t.bigint :account_id, null: false
      t.string :app_id, null: false
      t.jsonb :provider_config, null: false, default: {}

      t.timestamps
    end

    add_index :channel_google_play, [:account_id, :app_id], unique: true
  end
end
