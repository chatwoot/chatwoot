class CreateMacros < ActiveRecord::Migration[6.1]
  def change
    create_table :macros do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.integer :visibility, default: 0
      t.references :created_by, null: false, index: true, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, index: true, foreign_key: { to_table: :users }
      t.jsonb :actions, null: false, default: '{}'
      t.timestamps
      t.index :account_id, name: 'index_macros_on_account_id'
    end
  end
end
