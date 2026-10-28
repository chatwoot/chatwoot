# Email is matched on its own when identifying a widget visitor, so two people who happen to
# share an email (a family, a shared front-desk inbox) land on the same contact and overwrite
# each other's name/phone. This lets a contact's email repeat within an account as long as the
# phone number differs, so ContactIdentifyAction can keep such visitors as separate contacts.
class RelaxContactEmailUniquenessForPhoneNumber < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    execute <<~SQL.squish
      CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS uniq_email_phone_per_account_contact
      ON contacts (account_id, email, COALESCE(phone_number, ''))
    SQL

    remove_index :contacts, name: 'uniq_email_per_account_contact', if_exists: true
  end

  def down
    add_index :contacts, [:email, :account_id],
              unique: true,
              name: 'uniq_email_per_account_contact',
              algorithm: :concurrently,
              if_not_exists: true

    execute 'DROP INDEX CONCURRENTLY IF EXISTS uniq_email_phone_per_account_contact'
  end
end
