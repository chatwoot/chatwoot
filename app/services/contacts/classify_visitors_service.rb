# Classifies the contacts of one id window that are still visitors. A visitor with a sign of being a real
# person becomes a lead. A visitor with none, older than the retention period and not online, is deleted.
# Leads and customers are never read, changed or deleted.
class Contacts::ClassifyVisitorsService
  pattr_initialize [:from_id!, :to_id!]

  RETENTION = 30.days
  ROWS_PER_SECOND = 250
  SLICE = 500
  ONLINE_WINDOW = 5.minutes
  # Raised when a purged contact gained a conversation, note or label while the delete ran; rolls it back.
  class ContactTouchedError < StandardError; end
  RETRYABLE = [ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked, ActiveRecord::QueryCanceled, ContactTouchedError].freeze

  # Promotion follows Contacts::SyncAttributes, where blank means empty or whitespace. Purging follows
  # Contact.stale_without_conversations, which means exactly empty. A value made of whitespace is neither.
  IDENTITY = "(coalesce(contacts.email, '') ~ '\\S' OR coalesce(contacts.phone_number, '') ~ '\\S' " \
             "OR coalesce(contacts.identifier, '') ~ '\\S')".freeze
  NO_IDENTITY = "(coalesce(contacts.email, '') = '' AND coalesce(contacts.phone_number, '') = '' " \
                "AND coalesce(contacts.identifier, '') = '')".freeze
  # A social_* key whose value Ruby calls present: not null, false, {}, [] or a blank string.
  SOCIAL = "EXISTS (SELECT 1 FROM jsonb_each(CASE WHEN jsonb_typeof(contacts.additional_attributes) = 'object' " \
           "THEN contacts.additional_attributes ELSE '{}'::jsonb END) kv WHERE left(kv.key, 7) = 'social_' " \
           "AND kv.value NOT IN ('null'::jsonb, 'false'::jsonb, '{}'::jsonb, '[]'::jsonb) " \
           "AND NOT (jsonb_typeof(kv.value) = 'string' AND (kv.value #>> '{}') !~ '\\S'))".freeze
  # Someone created or handled the contact on purpose: a block, a company, a note, a label, a campaign
  # audience, an import, or a name that is not the one the widget generates for an anonymous visitor, such as quiet-fog-31.
  EXPLICIT = '(contacts.blocked OR contacts.company_id IS NOT NULL ' \
             "OR (coalesce(contacts.name, '') ~ '\\S' AND contacts.name !~ '^[a-z]+-[a-z]+-[0-9]{1,4}$') " \
             'OR EXISTS (SELECT 1 FROM notes WHERE notes.contact_id = contacts.id) ' \
             "OR EXISTS (SELECT 1 FROM taggings WHERE taggings.taggable_type = 'Contact' AND taggings.taggable_id = contacts.id) " \
             'OR EXISTS (SELECT 1 FROM campaign_recipients WHERE campaign_recipients.contact_id = contacts.id) ' \
             'OR EXISTS (SELECT 1 FROM data_import_mappings mappings ' \
             "WHERE mappings.chatwoot_record_type = 'Contact' AND mappings.chatwoot_record_id = contacts.id))".freeze
  VISITORS = <<~SQL.squish.freeze
    SELECT contacts.id, contacts.account_id,
           (#{IDENTITY} OR #{SOCIAL} OR #{EXPLICIT} OR contacts.last_activity_at IS NOT NULL
            OR EXISTS (SELECT 1 FROM conversations WHERE conversations.contact_id = contacts.id)) AS lead,
           (#{NO_IDENTITY} AND contacts.created_at < :cutoff) AS stale
    FROM contacts
    WHERE contacts.id BETWEEN :from_id AND :to_id AND contacts.contact_type = 0
    ORDER BY contacts.id
  SQL
  PROMOTE = 'UPDATE contacts SET contact_type = 1 WHERE id IN (:ids) AND contact_type = 0'.freeze

  def self.rows_per_second
    stored = Redis::Alfred.get(Redis::Alfred::CONTACT_TYPE_BACKFILL_RATE).to_f
    stored.positive? ? stored : ROWS_PER_SECOND
  end

  def perform
    rows = visitors
    leads, others = rows.partition { |row| row['lead'] }
    stale = others.select { |row| row['stale'] }
    { visitors: rows.size, promoted: promote(leads.pluck('id')), purged: purge(stale.map { |row| row.values_at('id', 'account_id') }) }
  end

  private

  def visitors
    Contact.connection.select_all(Contact.sanitize_sql_array([VISITORS, { from_id: from_id, to_id: to_id, cutoff: cutoff }])).to_a
  end

  def cutoff
    @cutoff ||= RETENTION.ago
  end

  # A plain UPDATE of the type: no callbacks, no updated_at change, no events. Only rows that are still
  # visitors change, so a repeat or a promotion by the app in the meantime is harmless.
  def promote(ids)
    ids.each_slice(SLICE).sum do |slice|
      paced(slice.size) { Contact.connection.exec_update(Contact.sanitize_sql_array([PROMOTE, { ids: slice }])) }
    end
  end

  def purge(pairs)
    pairs.each_slice(SLICE).sum do |slice|
      ids = slice.map(&:first) - online_ids(slice)
      paced(ids.size) { delete_stale(ids) }
    end
  end

  # Locks the rows that still match the rule, then deletes them with the whole rule evaluated again inside
  # the DELETE itself, so a conversation, note or label added in the meantime keeps the contact. Then the
  # contact inboxes and avatars of whichever contacts are gone.
  def delete_stale(ids)
    Contact.transaction do
      locked = stale(ids).lock.pluck(:id)
      stale(locked).where.not(id: Conversation.where(contact_id: locked).select(:contact_id)).delete_all
      purged = locked - Contact.where(id: locked).pluck(:id)
      raise ContactTouchedError if touched?(purged)

      ContactInbox.where(contact_id: purged).delete_all
      ActiveStorage::Attachment.where(record_type: 'Contact', record_id: purged).find_each(&:purge_later)
      purged.size
    end
  end

  # Writers of conversations, notes and labels do not lock the contact, so check once more before committing.
  def touched?(ids)
    Conversation.exists?(contact_id: ids) || Note.exists?(contact_id: ids) ||
      ActsAsTaggableOn::Tagging.exists?(taggable_type: 'Contact', taggable_id: ids)
  end

  def stale(ids)
    Contact.visitor.where(id: ids, last_activity_at: nil, created_at: ...cutoff)
           .where(NO_IDENTITY).where("NOT #{SOCIAL}").where("NOT #{EXPLICIT}")
  end

  # Stale candidates seen in the widget in the last few minutes.
  def online_ids(pairs)
    since = ONLINE_WINDOW.ago.to_i
    online = Redis::Alfred.pipelined do |pipeline|
      pairs.map(&:last).uniq.each do |account_id|
        pipeline.zrangebyscore(OnlineStatusTracker.presence_key(account_id, 'Contact'), since, '+inf')
      end
    end
    online.flatten.map(&:to_i) & pairs.map(&:first)
  end

  # Sleeps after each slice so the average stays under the rate and the database gets twice the
  # statement's own time to recover.
  def paced(rows, &)
    started = Time.current
    result = attempt(&)
    elapsed = Time.current - started
    sleep [rows.fdiv(self.class.rows_per_second) - elapsed, 2 * elapsed].max.clamp(0, 120)
    result
  end

  # A slice that keeps hitting a lock or a timeout fails the whole window, and the job retries it later.
  def attempt(tries = 3)
    yield
  rescue *RETRYABLE
    tries -= 1
    raise unless tries.positive?

    sleep 2
    retry
  end
end
