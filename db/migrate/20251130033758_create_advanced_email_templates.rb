class CreateAdvancedEmailTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :advanced_email_templates do |t|
      t.string :name, null: false
      t.string :friendly_name, null: false
      t.text :description
      t.string :template_type, null: false
      t.text :html, null: false
      t.references :account, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :advanced_email_templates, [:account_id, :name]
    add_index :advanced_email_templates, :template_type
  end
end
