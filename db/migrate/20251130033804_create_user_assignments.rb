class CreateUserAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :user_assignments do |t|
      t.references :advanced_email_template, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :active, default: false, null: false

      t.timestamps
    end

    add_index :user_assignments, [:advanced_email_template_id, :user_id],
              unique: true,
              name: 'index_user_assignments_on_template_and_user'
    add_index :user_assignments, [:user_id, :active]
  end
end
