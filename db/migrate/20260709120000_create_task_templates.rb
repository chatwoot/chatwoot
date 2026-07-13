class CreateTaskTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :task_templates do |t|
      t.references :account, null: false, foreign_key: true
      t.string :key, null: false
      t.string :title, null: false
      t.text :description
      t.references :default_team, foreign_key: { to_table: :teams }
      t.string :default_priority, null: false, default: 'normal'
      t.integer :default_due_offset_hours
      t.jsonb :metadata_schema, null: false, default: []
      t.jsonb :checklist_template, default: []
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :task_templates, [:account_id, :key], unique: true
    add_index :task_templates, [:account_id, :active, :position]
  end
end
