class CreateCaptainWorkflows < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_workflows do |t|
      t.string :name, null: false
      t.text :description
      t.references :account, null: false
      t.references :assistant, null: false
      t.string :trigger_event, null: false
      t.jsonb :trigger_conditions, default: {}
      t.jsonb :nodes, default: []
      t.jsonb :edges, default: []
      t.boolean :enabled, default: false, null: false

      t.timestamps
    end

    add_index :captain_workflows, [:account_id, :trigger_event, :enabled], name: 'index_captain_workflows_on_account_event_enabled'
  end
end
