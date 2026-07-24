class CreateConversationFlows < ActiveRecord::Migration[7.1]
  def change
    create_table :flows do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.jsonb :graph, null: false, default: {}
      t.jsonb :exit_policy, null: false, default: {}
      t.timestamps
    end
    add_index :flows, [:account_id, :name], unique: true

    create_table :flow_runs do |t|
      t.references :flow, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.integer :state, null: false, default: 0
      t.string :current_node_id
      t.jsonb :variables, null: false, default: {}
      t.jsonb :trail, null: false, default: []
      t.string :trigger, default: 'automation_rule'
      t.datetime :started_at
      t.datetime :ended_at
      t.string :ended_reason
      t.timestamps
    end
    add_index :flow_runs, [:conversation_id, :state]
    add_index :flow_runs, :state

    create_table :flow_events do |t|
      t.references :flow_run, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :node_id
      t.jsonb :data, default: {}
      t.datetime :created_at, null: false
    end
    add_index :flow_events, [:flow_run_id, :event_type]
  end
end
