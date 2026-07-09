class CreateCrmMetaConversionEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_meta_conversion_events do |t|
      t.bigint :account_id, null: false
      t.bigint :pipeline_id
      t.bigint :card_id, index: { name: 'idx_crm_meta_conv_card' }
      t.string :event_type, null: false
      t.string :funnel_stage_type
      t.string :ctwa_clid
      t.bigint :value_cents
      t.string :currency
      t.string :dataset_id
      t.string :event_id, null: false, index: { unique: true, name: 'idx_crm_meta_conv_event_id' }
      t.integer :status, default: 0, null: false
      t.integer :http_code
      t.text :error_message
      t.string :source, default: 'live', null: false
      t.datetime :sent_at

      t.timestamps
    end

    add_index :crm_meta_conversion_events, %i[account_id created_at], name: 'idx_crm_meta_conv_account_created'
  end
end
