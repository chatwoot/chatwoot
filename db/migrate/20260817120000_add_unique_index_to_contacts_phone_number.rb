class AddUniqueIndexToContactsPhoneNumber < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_contacts_on_phone_number_and_account_id'.freeze
  NEW_INDEX_NAME = 'uniq_phone_number_per_account_contact'.freeze
  MAX_ATTEMPTS = 5

  def up
    remove_index :contacts, name: OLD_INDEX_NAME, algorithm: :concurrently if index_name_exists?(:contacts, OLD_INDEX_NAME)

    build_unique_index_with_retries!
  end

  def down
    remove_index :contacts, name: NEW_INDEX_NAME, algorithm: :concurrently if index_name_exists?(:contacts, NEW_INDEX_NAME)
    unless index_name_exists?(:contacts, OLD_INDEX_NAME)
      add_index :contacts, [:phone_number, :account_id], name: OLD_INDEX_NAME, algorithm: :concurrently
    end
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
  #
  # This is idempotent and safe to call multiple times (a row already deduped has
  # phone_number NULL and drops out of the WHERE clause).
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

  # Building a unique index CONCURRENTLY cannot run inside a transaction (hence
  # disable_ddl_transaction! above), so on a busy installation a contact insert or
  # phone_number update can commit a fresh duplicate after dedupe_phone_numbers!
  # finishes but before (or during) the concurrent index build. When that happens
  # Postgres aborts the build with a unique-violation error and leaves the new
  # index behind marked INVALID instead of rolling it back. A plain re-run of this
  # migration would then fail again immediately, because CREATE INDEX CONCURRENTLY
  # refuses to reuse that name while the invalid index still exists.
  #
  # This method makes the migration safe to retry: every attempt first drops any
  # invalid leftover index from a prior failed attempt, re-runs the (idempotent)
  # dedupe, and tries the build again, up to MAX_ATTEMPTS times. This does not
  # make the write race impossible -- a duplicate could still land in the instant
  # between the final dedupe and the index becoming valid -- but each retry
  # shrinks that window to a single index build, and the migration converges
  # instead of getting stuck. Prefer running this during a low-write window if one
  # is available; the retry loop is the safety net for installations where that
  # isn't practical.
  def build_unique_index_with_retries!
    attempt = 0

    begin
      attempt += 1
      drop_stale_invalid_index!
      dedupe_phone_numbers!

      add_index :contacts, [:phone_number, :account_id],
                unique: true,
                where: "phone_number IS NOT NULL AND phone_number <> ''",
                name: NEW_INDEX_NAME,
                algorithm: :concurrently
    rescue ActiveRecord::RecordNotUnique => e
      if attempt < MAX_ATTEMPTS
        Rails.logger.warn(
          "[#{self.class}] concurrent write raced the unique index build on contacts " \
          "(attempt #{attempt}/#{MAX_ATTEMPTS}), retrying: #{e.message}"
        )
        retry
      end

      drop_stale_invalid_index!
      raise "Failed to build #{NEW_INDEX_NAME} after #{MAX_ATTEMPTS} attempts because of " \
            "concurrent writes to contacts.phone_number racing the index build. Re-run this " \
            "migration during a quieter write window. Original error: #{e.message}"
    end
  end

  # A failed CREATE UNIQUE INDEX CONCURRENTLY does not roll back (DDL
  # transactions are disabled for this migration); it leaves the index behind
  # marked invalid in pg_index. DROP INDEX CONCURRENTLY IF EXISTS is a no-op when
  # the index doesn't exist, so this only ever removes a genuinely invalid
  # leftover -- a valid index (e.g. from a prior successful run) is left alone.
  def drop_stale_invalid_index!
    invalid_index_present = select_value(<<~SQL.squish)
      SELECT 1
      FROM pg_class c
      JOIN pg_index i ON i.indexrelid = c.oid
      WHERE c.relname = #{connection.quote(NEW_INDEX_NAME)} AND NOT i.indisvalid
    SQL

    return unless invalid_index_present

    Rails.logger.warn("[#{self.class}] dropping invalid leftover index #{NEW_INDEX_NAME} from a prior failed attempt")
    execute("DROP INDEX CONCURRENTLY IF EXISTS #{NEW_INDEX_NAME}")
  end
end
