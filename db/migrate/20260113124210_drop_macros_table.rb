class DropMacrosTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :macros do |t|
      t.jsonb :actions, null: false
      t.string :name, null: false
      t.integer :visibility, default: 0
      t.bigint :account_id, null: false
      t.bigint :created_by_id
      t.bigint :updated_by_id
      t.timestamps
    end
  end
end
