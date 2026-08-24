class CreateConversationFlows < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_flows do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.text :description
      t.jsonb :flow_data, null: false, default: {}
      t.boolean :enabled, null: false, default: false
      t.integer :execution_count, default: 0
      t.timestamps
    end

    add_index :conversation_flows, :account_id
    add_index :conversation_flows, [:account_id, :enabled]
  end
end
