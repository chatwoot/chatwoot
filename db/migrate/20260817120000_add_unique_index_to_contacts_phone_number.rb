class AddUniqueIndexToContactsPhoneNumber < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    dedupe_phone_numbers!

    remove_index :contacts, name: 'index_contacts_on_phone_number_and_account_id', algorithm: :concurrently
    add_index :contacts, [:phone_number, :account_id],
              unique: true,
              where: "phone_number IS NOT NULL AND phone_number <> ''",
              name: 'uniq_phone_number_per_account_contact',
              algorithm: :concurrently
  end

  def down
    remove_index :contacts, name: 'uniq_phone_number_per_account_contact', algorithm: :concurrently
    add_index :contacts, [:phone_number, :account_id], name: 'index_contacts_on_phone_number_and_account_id', algorithm: :concurrently
  end

  private

  # Concurrent contact creation (e.g. simultaneous webhook deliveries for the same
  # phone number) could previously slip past the model-level uniqueness validation
  # and insert duplicate (account_id, phone_number) rows, since the DB had no unique
  # constraint backing it.
  #
  # Contact rows are never deleted here: they can be referenced by conversations,
  # messages, notes, etc., so silently dropping a duplicate row could destroy
  # conversation history. Instead, for every duplicate group we keep the oldest row
  # (lowest id) untouched and nullify phone_number on the newer duplicates, which
  # matches how blank phone numbers are already represented in this table
  # (see Contact#prepare_email_attribute for the equivalent handling of email).
  def dedupe_phone_numbers!
    execute <<~SQL.squish
      UPDATE contacts
      SET phone_number = NULL
      WHERE id IN (
        SELECT id FROM (
          SELECT id,
                 ROW_NUMBER() OVER (
                   PARTITION BY account_id, phone_number
                   ORDER BY id ASC
                 ) AS row_number
          FROM contacts
          WHERE phone_number IS NOT NULL AND phone_number <> ''
        ) duplicate_phone_numbers
        WHERE row_number > 1
      )
    SQL
  end
end
