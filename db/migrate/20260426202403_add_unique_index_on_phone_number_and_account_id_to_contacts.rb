class AddUniqueIndexOnPhoneNumberAndAccountIdToContacts < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    if duplicate_phone_numbers_exist?
      raise ActiveRecord::IrreversibleMigration, <<~MESSAGE
        Cannot add unique index uniq_phone_number_per_account_contact because duplicate
        non-empty phone numbers already exist per account in contacts.
        Please deduplicate existing contacts and re-run this migration.
      MESSAGE
    end

    # Remove existing non-unique index first
    remove_index :contacts,
                 name: 'index_contacts_on_phone_number_and_account_id',
                 algorithm: :concurrently,
                 if_exists: true

    # Add unique constraint matching email and identifier pattern
    # allow_blank: true means NULL and empty string are allowed
    # We use a partial index to only enforce uniqueness on non-blank phone numbers
    add_index :contacts, [:phone_number, :account_id],
              unique: true,
              where: "phone_number IS NOT NULL AND phone_number != ''",
              name: 'uniq_phone_number_per_account_contact',
              algorithm: :concurrently
  end

  def down
    remove_index :contacts,
                 name: 'uniq_phone_number_per_account_contact',
                 algorithm: :concurrently,
                 if_exists: true

    add_index :contacts, [:phone_number, :account_id],
              name: 'index_contacts_on_phone_number_and_account_id',
              algorithm: :concurrently
  end

  private

  def duplicate_phone_numbers_exist?
    duplicate_rows_sql = <<~SQL.squish
      SELECT 1
      FROM contacts
      WHERE phone_number IS NOT NULL AND phone_number != ''
      GROUP BY account_id, phone_number
      HAVING COUNT(*) > 1
      LIMIT 1
    SQL

    connection.select_value(duplicate_rows_sql).present?
  end
end
