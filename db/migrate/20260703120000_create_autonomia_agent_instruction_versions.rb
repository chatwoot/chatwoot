class CreateAutonomiaAgentInstructionVersions < ActiveRecord::Migration[7.0]
  def change
    create_table :autonomia_agent_instruction_versions do |t|
      t.references :autonomia_agent, null: false,
                                     foreign_key: { on_delete: :cascade },
                                     index: { name: 'idx_autonomia_instruction_versions_on_agent_id' }
      t.references :account, null: false, foreign_key: true,
                             index: { name: 'idx_autonomia_instruction_versions_on_account_id' }
      t.text :instruction, null: false
      t.string :instruction_hash, null: false
      t.string :reason, null: false
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify },
                                index: { name: 'idx_autonomia_instruction_versions_on_created_by' }
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :autonomia_agent_instruction_versions, [:autonomia_agent_id, :created_at],
              name: 'idx_autonomia_instruction_versions_agent_created'
  end
end
