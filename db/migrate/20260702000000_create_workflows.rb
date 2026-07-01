class CreateWorkflows < ActiveRecord::Migration[7.1]
  def change
    create_table :workflows do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :trigger_event, null: false
      t.boolean :active, default: true
      t.jsonb :nodes, default: [], null: false
      t.jsonb :edges, default: [], null: false

      t.timestamps
    end

    add_index :workflows, [:account_id, :trigger_event, :active]
  end
end
