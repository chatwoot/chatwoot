class AddBsuidToResolvedContactsIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  # `Contact.resolved_contacts` treats a contact as resolved when it carries an identity. A
  # WhatsApp contact identified only by a business scoped user id carries one, but not in any of
  # the three columns the predicate looks at, so it stayed out of the contacts list.
  #
  # The mirrored identifier is read instead of joining `contact_inboxes`, because a join takes the
  # predicate off this table and a partial index cannot cover it. Measured on a 168k contact
  # account: the join form costs 524ms against 23ms for the indexed one.
  # The condition has to match the one `Contact.resolved_contacts` builds. A broader one, such as
  # `IS NOT NULL`, is not enough: Postgres will not use the index for a query it cannot prove the
  # predicate from, and the scan quietly falls back to a sequential one.
  RESOLVED = "email <> '' OR phone_number <> '' OR identifier <> ''".freeze
  RESOLVED_WITH_BSUID = "#{RESOLVED} OR additional_attributes->>'whatsapp_bsuid' > ''".freeze

  def up
    add_index :contacts, :account_id, where: RESOLVED_WITH_BSUID,
                                      name: 'index_resolved_contact_account_id_v2',
                                      algorithm: :concurrently, if_not_exists: true
    remove_index :contacts, name: 'index_resolved_contact_account_id',
                            algorithm: :concurrently, if_exists: true
  end

  def down
    add_index :contacts, :account_id, where: RESOLVED,
                                      name: 'index_resolved_contact_account_id',
                                      algorithm: :concurrently, if_not_exists: true
    remove_index :contacts, name: 'index_resolved_contact_account_id_v2',
                            algorithm: :concurrently, if_exists: true
  end
end
