class CreateCaptainScenarios < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_scenarios do |t|
      t.string :title
      t.text :description
      t.text :instruction
      t.jsonb :tools
      t.boolean :enabled, default: true, null: false
      t.references :assistant, null: false, foreign_key: { to_table: :captain_assistants }
      t.references :account, null: false

      t.timestamps
    end

    add_index :captain_scenarios, :enabled
    add_index :captain_scenarios, [:assistant_id, :enabled]
  end
end
