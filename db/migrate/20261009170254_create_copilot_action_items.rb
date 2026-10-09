class CreateCopilotActionItems < ActiveRecord::Migration[7.2]
  def change
    create_table :copilot_action_items do |t|
      t.references :copilot_run, null: false
      t.bigint :record_id, null: false
      t.string :status, null: false
      t.string :error
      t.integer :attempts, null: false, default: 0
      t.timestamps
    end
    add_index :copilot_action_items, [:copilot_run_id, :record_id], unique: true
  end
end
