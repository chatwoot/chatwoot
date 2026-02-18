class CreateCrmFlows < ActiveRecord::Migration[7.0]
  def change
    create_table :crm_flows do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, foreign_key: true
      t.string :name, null: false
      t.string :trigger_type, null: false
      t.string :scope_type, null: false, default: 'global'
      t.jsonb :actions, null: false, default: []
      t.jsonb :required_fields, default: []
      t.integer :dedup_window_minutes, default: 60
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :crm_flows, [:account_id, :trigger_type]
    add_index :crm_flows, [:account_id, :active]
  end
end
