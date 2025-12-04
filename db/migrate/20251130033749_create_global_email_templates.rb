class CreateGlobalEmailTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :global_email_templates do |t|
      t.string :name, null: false
      t.string :friendly_name, null: false
      t.text :description
      t.string :template_type, null: false
      t.text :html, null: false

      t.timestamps
    end

    add_index :global_email_templates, :name, unique: true
    add_index :global_email_templates, :template_type
  end
end
