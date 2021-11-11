class CreateAutomationRules < ActiveRecord::Migration[6.1]
  def change
    create_table :automation_rules do |t|
      t.bigint :account_id, null: false
      t.string :name
      t.text :description
      t.string :event_name
      t.jsonb :conditions
      t.jsonb :actions
      t.timestamps
      t.index :account_id, name: 'index_automation_rules_on_account_id'
    end
  end
end
