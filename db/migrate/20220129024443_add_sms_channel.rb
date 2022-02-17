class AddSmsChannel < ActiveRecord::Migration[6.1]
  def change
    create_table :channel_sms do |t|
      t.integer :account_id, null: false
      t.string :phone_number, null: false, index: { unique: true }
      t.string :provider, default: 'default'
      t.jsonb :provider_config, default: {}
      t.timestamps
    end
  end
end
