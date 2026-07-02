class UpdateEmailTemplatesUniqueIndexForLocaleAndType < ActiveRecord::Migration[7.1]
  def change
    remove_index :email_templates, name: 'index_email_templates_on_name_and_account_id'
    add_index :email_templates,
              [:name, :account_id, :template_type, :locale],
              unique: true,
              name: 'index_email_templates_on_name_account_type_locale'
  end
end
