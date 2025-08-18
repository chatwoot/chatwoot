class CreateSlaEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :sla_events do |t|
      t.references :applied_sla, null: false
      t.references :conversation, null: false
      t.references :account, null: false
      t.references :sla_policy, null: false
      t.references :inbox, null: false

      t.integer :event_type
      t.jsonb :meta, default: {}

      t.timestamps
    end
  end
end
