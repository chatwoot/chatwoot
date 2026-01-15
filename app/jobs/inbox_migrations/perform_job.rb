# frozen_string_literal: true

# InboxMigrations::PerformJob
#
# Background job that executes an inbox conversation migration.
# Uses advisory locking to prevent concurrent migrations on the same source inbox.
#
# This job is designed to be idempotent and safe to retry:
# - If the migration is already running or completed, it will not re-run
# - If the migration fails, it can be retried by creating a new migration
#
module InboxMigrations
  class PerformJob < ApplicationJob
    queue_as :low

    # Don't retry automatically - migrations should be explicitly re-triggered
    discard_on StandardError do |job, error|
      migration = InboxMigration.find_by(id: job.arguments.first)
      migration.mark_failed!(error.message, error.backtrace) if migration&.running?
      Rails.logger.error("[InboxMigration] Job failed: #{error.message}")
      Rails.logger.error(error.backtrace&.first(10)&.join("\n"))
    end

    def perform(inbox_migration_id)
      migration = InboxMigration.find(inbox_migration_id)

      # Skip if not in queued state (already running, completed, failed, or cancelled)
      unless migration.queued?
        Rails.logger.info("[InboxMigration #{migration.id}] Skipping - status is #{migration.status}")
        return
      end

      # Use advisory lock to prevent concurrent migrations on the same source inbox
      lock_key = "inbox_migration_#{migration.source_inbox_id}"

      acquired = with_advisory_lock(lock_key) do
        execute_migration(migration)
      end

      return if acquired

      Rails.logger.warn("[InboxMigration #{migration.id}] Could not acquire lock - another migration may be running")
      migration.mark_failed!('Could not acquire migration lock - another migration may be in progress')
    end

    private

    def execute_migration(migration)
      Rails.logger.info("[InboxMigration #{migration.id}] Starting migration job")

      migration.mark_running!

      service = MigrateConversationsService.new(migration)
      service.execute!

      migration.mark_completed!

      Rails.logger.info("[InboxMigration #{migration.id}] Migration completed successfully")
    rescue StandardError => e
      Rails.logger.error("[InboxMigration #{migration.id}] Migration failed: #{e.message}")
      Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
      migration.mark_failed!(e.message, e.backtrace)
      raise # Re-raise to trigger discard_on handler
    end

    def with_advisory_lock(lock_key, timeout: 0)
      # PostgreSQL advisory lock using a hash of the lock key
      lock_id = Zlib.crc32(lock_key)

      # Try to acquire the lock (non-blocking)
      result = ActiveRecord::Base.connection.execute(
        "SELECT pg_try_advisory_lock(#{lock_id}) AS locked"
      ).first

      return false unless result['locked']

      begin
        yield
        true
      ensure
        # Release the lock
        ActiveRecord::Base.connection.execute("SELECT pg_advisory_unlock(#{lock_id})")
      end
    end
  end
end
