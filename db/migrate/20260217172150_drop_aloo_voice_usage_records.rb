# frozen_string_literal: true

class DropAlooVoiceUsageRecords < ActiveRecord::Migration[7.1]
  def up
    drop_table :aloo_voice_usage_records, if_exists: true
  end

  def down
    create_table :aloo_voice_usage_records do |t|
      t.references :account, null: false, index: true
      t.bigint :aloo_assistant_id, null: false
      t.references :message, null: true

      t.string :operation_type, null: false
      t.string :provider, null: false
      t.string :status, null: false, default: 'success'
      t.integer :characters_used, default: 0
      t.integer :audio_duration_seconds, default: 0
      t.string :voice_id
      t.string :model_used
      t.decimal :estimated_cost, precision: 10, scale: 6
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :aloo_voice_usage_records, :aloo_assistant_id
    add_index :aloo_voice_usage_records, :operation_type
    add_index :aloo_voice_usage_records, :status
    add_index :aloo_voice_usage_records, :created_at
  end
end
