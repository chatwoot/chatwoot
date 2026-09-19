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

  # Frozen here rather than read from `RegexHelper::WHATSAPP_BSUID_PATTERN`, because a migration has
  # to keep producing the same result on a future checkout even if that constant is later widened.
  BSUID = '[A-Z]{2}\.(ENT\.)?[A-Za-z0-9]{1,128}'.freeze
  BSUID_SOURCE_ID = "^(whatsapp:)?#{BSUID}$".freeze
  PARENT_SOURCE_ID = '^(whatsapp:)?[A-Z]{2}\.ENT\.'.freeze

  # Only a WhatsApp inbox assigns a business scoped identifier. Every other channel is free to pick
  # its own source id, and the public contacts endpoint takes one straight from the caller, so a
  # value shaped like `AB.customer` can legitimately exist outside WhatsApp. Reading it would mirror
  # a WhatsApp identity onto a contact that has none and pull it into lists, search and exports.
  WHATSAPP_INBOX_JOIN = <<~SQL.squish.freeze
    JOIN inboxes ON inboxes.id = contact_inboxes.inbox_id
    LEFT JOIN channel_twilio_sms ON inboxes.channel_type = 'Channel::TwilioSms'
                                AND channel_twilio_sms.id = inboxes.channel_id
  SQL

  # Twilio carries WhatsApp on the same channel it carries SMS, told apart by `medium`, so the
  # channel type alone would take the SMS inboxes along with it.
  WHATSAPP_INBOX = <<~SQL.squish.freeze
    (inboxes.channel_type = 'Channel::Whatsapp'
     OR (inboxes.channel_type = 'Channel::TwilioSms' AND channel_twilio_sms.medium = 1))
  SQL

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
      FROM (#{owned_aliases_sql}) AS owned
      WHERE contacts.id = owned.contact_id
    SQL
  end

  def owned_aliases_sql
    <<~SQL.squish
      SELECT DISTINCT ON (contact_inboxes.contact_id)
             contact_inboxes.contact_id,
             regexp_replace(contact_inboxes.source_id, '^whatsapp:', '') AS identifier
      FROM contact_inboxes
      JOIN contacts AS pending ON pending.id = contact_inboxes.contact_id
      #{WHATSAPP_INBOX_JOIN}
      WHERE #{WHATSAPP_INBOX}
        AND contact_inboxes.source_id ~ '#{BSUID_SOURCE_ID}'
        AND COALESCE(pending.additional_attributes->>'whatsapp_bsuid', '') = ''
      ORDER BY contact_inboxes.contact_id,
               (contact_inboxes.source_id ~ '#{PARENT_SOURCE_ID}'),
               contact_inboxes.id
      LIMIT #{BATCH_SIZE}
    SQL
  end
end
