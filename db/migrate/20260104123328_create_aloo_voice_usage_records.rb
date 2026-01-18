# frozen_string_literal: true

class CreateAlooVoiceUsageRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :aloo_voice_usage_records do |t|
      t.references :account, null: false, foreign_key: true
      t.references :aloo_assistant, null: false, foreign_key: true
      t.references :message, null: true, foreign_key: true
      t.string :operation_type, null: false # 'transcription' or 'synthesis'
      t.string :provider, null: false # 'openai', 'elevenlabs'
      t.integer :characters_used, default: 0
      t.integer :audio_duration_seconds, default: 0
      t.decimal :estimated_cost, precision: 10, scale: 6
      t.string :model_used
      t.string :voice_id
      t.string :status, default: 'success' # 'success', 'failed'
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :aloo_voice_usage_records, %i[account_id created_at]
    add_index :aloo_voice_usage_records, %i[account_id operation_type]
    add_index :aloo_voice_usage_records, :created_at
  end
end
