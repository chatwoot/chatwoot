class CreateSearchIndexStates < ActiveRecord::Migration[7.1]
  def change
    create_table :search_index_states do |t|
      # Retained after account deletion until indexed source data has been purged.
      t.bigint :account_id, null: false
      t.string :entity, null: false
      t.string :epoch, null: false
      t.integer :schema_version, null: false
      t.string :run_token, null: false
      t.string :status, null: false, default: 'running'
      t.string :phase, null: false, default: 'scan'
      t.bigint :cursor, null: false, default: 0
      t.bigint :upper_id, null: false, default: 0
      t.bigint :scanned_count, null: false, default: 0
      t.bigint :repaired_count, null: false, default: 0
      t.bigint :pass_repairs, null: false, default: 0
      t.datetime :ready_at
      t.string :last_error
      t.timestamps
    end
    add_index :search_index_states, [:account_id, :entity], unique: true
    add_index :search_index_states, [:status, :updated_at]
  end
end
