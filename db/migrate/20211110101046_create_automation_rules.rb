class CreateAutomationRules < ActiveRecord::Migration[6.1]
  def change
    create_table :automation_rules do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.text :description
      t.string :event_name, null: false
      t.jsonb :conditions, null: false, default: '{}'
      t.jsonb :actions, null: false, default: '{}'
      t.timestamps
      t.index :account_id, name: 'index_automation_rules_on_account_id'
    end
  end
end
