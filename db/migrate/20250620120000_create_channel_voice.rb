class CreateChannelVoice < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_voice do |t|
      t.string :phone_number, null: false
      t.string :provider, null: false, default: 'twilio'
      t.jsonb :provider_config, null: false
      t.integer :account_id, null: false
      t.jsonb :additional_attributes, default: {}

      t.timestamps
    end

    add_index :channel_voice, :phone_number, unique: true
    add_index :channel_voice, :account_id
  end
end
