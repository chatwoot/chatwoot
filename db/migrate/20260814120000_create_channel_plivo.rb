class CreateChannelPlivo < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_plivo do |t|
      t.string :phone_number, null: false
      t.jsonb :provider_config, default: {}
      t.integer :account_id, null: false
      t.timestamps
    end

    add_index :channel_plivo, :phone_number, unique: true
  end
end
