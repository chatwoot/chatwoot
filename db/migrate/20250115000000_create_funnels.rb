class CreateFunnels < ActiveRecord::Migration[7.1]
  def change
    create_table :funnels do |t|
      t.string :name, null: false
      t.bigint :account_id, null: false
      t.bigint :team_id
      t.jsonb :columns, default: [], null: false
      t.integer :position, default: 0
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :funnels, :account_id
    add_index :funnels, :team_id
    add_index :funnels, [:account_id, :name], unique: true
    add_index :funnels, [:account_id, :is_default], where: 'is_default = true', unique: true
    add_foreign_key :funnels, :accounts, on_delete: :cascade
    add_foreign_key :funnels, :teams, on_delete: :nullify
  end
end
