class CreateChannelVoiceTable < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_voice do |t|
      t.integer :account_id, null: false
      t.string :phone_number, null: false
      t.jsonb :additional_attributes, default: {}

      t.timestamps
    end

    add_index :channel_voice, [:account_id, :phone_number], unique: true
  end
end
