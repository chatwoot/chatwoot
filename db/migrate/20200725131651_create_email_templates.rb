class CreateEmailTemplates < ActiveRecord::Migration[6.0]
  def change
    create_table :email_templates do |t|
      t.string :name, null: false
      t.text :body, null: false
      t.integer :account_id, null: true
      t.integer :template_type, default: 1
      t.integer :locale, default: 0, null: false
      t.timestamps
    end
    add_index :email_templates, [:name, :account_id], unique: true
  end
end
