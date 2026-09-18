class AddBsuidToResolvedContactsIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  # `Contact.resolved_contacts` treats a contact as resolved when it carries an identity. A WhatsApp
  # contact identified only by a business scoped user id carries one, but not in any of the three
  # columns the predicate looks at, so it stayed out of the contacts list.
  #
  # The mirrored identifier is read instead of joining `contact_inboxes`, because a join takes the
  # predicate off this table and a partial index cannot cover it. Measured on a 168k contact
  # account: the join form costs 524ms against 23ms for the indexed one.
  #
  # The condition has to match the one `Contact.resolved_contacts` builds. A broader one, such as
  # `IS NOT NULL`, is not enough: Postgres will not use an index whose predicate it cannot derive
  # from the query, and the scan quietly falls back to a sequential one.
  RESOLVED = "email <> '' OR phone_number <> '' OR identifier <> ''".freeze
  RESOLVED_WITH_BSUID = "#{RESOLVED} OR additional_attributes->>'whatsapp_bsuid' > ''".freeze

  BATCH_SIZE = 5_000

  def up
    backfill_mirrored_bsuid
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

  private

  # A contact that stopped messaging before the identifier started being mirrored keeps it only in
  # `contact_inboxes.source_id`, so the predicate above would pass it over until the next inbound
  # payload, which for an inactive contact may never arrive. The rows already exist, so this reads
  # them rather than waiting.
  #
  # A regular identifier is preferred over a parent one, the same order `bsuid_attributes` applies,
  # and only aliases the contact owns are read. Batched because the join is over every contact inbox.
  #
  # Twilio stores the alias with a `whatsapp:` prefix while the mirror holds the bare identifier, so
  # the match allows the prefix and the write strips it. Reading the raw column would both skip every
  # Twilio contact and, where it did match, mirror a value in a shape nothing else writes.
  def backfill_mirrored_bsuid
    loop { break if execute(backfill_sql).cmd_tuples.zero? }
  end

  def backfill_sql
    <<~SQL.squish
      UPDATE contacts
      SET additional_attributes = COALESCE(contacts.additional_attributes, '{}'::jsonb)
                                  || jsonb_build_object('whatsapp_bsuid', owned.identifier)
      FROM (
        SELECT DISTINCT ON (contact_inboxes.contact_id)
               contact_inboxes.contact_id,
               regexp_replace(contact_inboxes.source_id, '^whatsapp:', '') AS identifier
        FROM contact_inboxes
        JOIN contacts AS pending ON pending.id = contact_inboxes.contact_id
        WHERE contact_inboxes.source_id ~ '^(whatsapp:)?[A-Z]{2}\\.'
          AND COALESCE(pending.additional_attributes->>'whatsapp_bsuid', '') = ''
        ORDER BY contact_inboxes.contact_id,
                 (contact_inboxes.source_id ~ '^(whatsapp:)?[A-Z]{2}\\.ENT\\.'),
                 contact_inboxes.id
        LIMIT #{BATCH_SIZE}
      ) AS owned
      WHERE contacts.id = owned.contact_id
    SQL
  end
end
