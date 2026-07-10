class CreateCrmGoogleConversionEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_google_conversion_events do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :card_id, null: false
      t.bigint :conversation_id
      t.bigint :activity_id, null: false
      t.string :event_id, null: false
      t.string :gclid
      t.string :conversion_name, null: false
      t.datetime :conversion_time, null: false
      t.bigint :value_cents
      t.string :currency, limit: 3
      t.string :status, null: false, default: 'ready'
      t.string :skip_reason

      t.timestamps
    end

    add_index :crm_google_conversion_events, :event_id, unique: true, name: 'idx_crm_google_conv_event_id'
    add_index :crm_google_conversion_events, %i[account_id conversion_time], name: 'idx_crm_google_conv_account_time'
    add_index :crm_google_conversion_events, %i[account_id status], name: 'idx_crm_google_conv_account_status'
  end
end
