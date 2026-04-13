class CreateContactEmails < ActiveRecord::Migration[7.0]
  def up
    create_table :contact_emails do |t|
      t.references :account, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.string :email, null: false
      t.boolean :primary, null: false, default: false

      t.timestamps
    end

    add_index :contact_emails, 'LOWER(email), account_id',
              unique: true,
              name: 'index_contact_emails_on_lower_email_account_id'
    add_index :contact_emails, :contact_id,
              unique: true,
              where: '"primary" = TRUE',
              name: 'index_contact_emails_on_contact_id_primary_unique'

    execute <<~SQL.squish
      INSERT INTO contact_emails (account_id, contact_id, email, primary, created_at, updated_at)
      SELECT contacts.account_id, contacts.id, LOWER(contacts.email), TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM contacts
      WHERE contacts.email IS NOT NULL AND contacts.email <> ''
    SQL
  end

  def down
    drop_table :contact_emails
  end
end
