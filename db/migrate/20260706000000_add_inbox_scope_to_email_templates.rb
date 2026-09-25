class AddInboxScopeToEmailTemplates < ActiveRecord::Migration[7.1]
  def up
    add_column :email_templates, :inbox_id, :integer
    add_index :email_templates, :inbox_id, name: 'index_email_templates_on_inbox_id'

    remove_index :email_templates, name: 'index_email_templates_on_name_and_account_id'
    ensure_no_duplicate_installation_templates!
    add_index :email_templates,
              [:name, :template_type, :locale],
              unique: true,
              where: 'account_id IS NULL AND inbox_id IS NULL',
              name: 'index_email_templates_on_installation_scope'
    add_index :email_templates,
              [:account_id, :name, :template_type, :locale],
              unique: true,
              where: 'account_id IS NOT NULL AND inbox_id IS NULL',
              name: 'index_email_templates_on_account_scope'
    add_index :email_templates,
              [:inbox_id, :name, :template_type, :locale],
              unique: true,
              where: 'inbox_id IS NOT NULL',
              name: 'index_email_templates_on_inbox_scope'
  end

  def down
    remove_index :email_templates, name: 'index_email_templates_on_inbox_scope'
    remove_index :email_templates, name: 'index_email_templates_on_account_scope'
    remove_index :email_templates, name: 'index_email_templates_on_installation_scope'
    remove_index :email_templates, name: 'index_email_templates_on_inbox_id'

    add_index :email_templates, [:name, :account_id], unique: true, name: 'index_email_templates_on_name_and_account_id'
    remove_column :email_templates, :inbox_id
  end

  private

  def ensure_no_duplicate_installation_templates!
    duplicates = select_values <<~SQL.squish
      SELECT CONCAT(name, '/', template_type, '/', locale)
      FROM email_templates
      WHERE account_id IS NULL
      GROUP BY name, template_type, locale
      HAVING COUNT(*) > 1
    SQL
    return if duplicates.empty?

    raise ActiveRecord::IrreversibleMigration,
          "Duplicate installation email templates must be resolved before migrating: #{duplicates.join(', ')}"
  end
end
