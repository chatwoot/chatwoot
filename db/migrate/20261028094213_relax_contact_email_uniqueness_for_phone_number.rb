# Email is matched on its own when identifying a widget visitor, so two people who happen to
# share an email (a family, a shared front-desk inbox) land on the same contact and overwrite
# each other's name/phone. This lets a contact's email repeat within an account as long as the
# phone number differs, so ContactIdentifyAction can keep such visitors as separate contacts.
#
# The single old index is replaced by two partial ones: contacts with no phone number still
# enforce the original one-contact-per-email rule among themselves, and contacts with a phone
# number are unique per (email, phone_number), so only a differing phone number lets an email
# repeat. See ContactEmailIdentity for the matching model-level rule.
class RelaxContactEmailUniquenessForPhoneNumber < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    add_index :contacts, [:account_id, :email],
              unique: true,
              where: "phone_number IS NULL OR phone_number = ''",
              name: 'uniq_email_per_account_contact_without_phone',
              algorithm: :concurrently,
              if_not_exists: true

    add_index :contacts, [:account_id, :email, :phone_number],
              unique: true,
              where: "phone_number IS NOT NULL AND phone_number <> ''",
              name: 'uniq_email_phone_per_account_contact',
              algorithm: :concurrently,
              if_not_exists: true

    remove_index :contacts, name: 'uniq_email_per_account_contact', algorithm: :concurrently, if_exists: true
  end

  # Once contacts share an email under different phone numbers, the old email-only unique index
  # can't be rebuilt without deciding which of them to merge or delete.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
