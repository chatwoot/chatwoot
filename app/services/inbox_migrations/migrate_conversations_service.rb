# frozen_string_literal: true

# InboxMigrations::MigrateConversationsService
#
# Moves conversations, messages, attachments, and contacts from a source inbox
# to a destination inbox. Handles contact conflicts by merging contacts that
# share the same source_id (WhatsApp phone number).
#
# This service is designed to be idempotent and safe to retry. It processes
# data in batches to avoid long-running transactions and database locks.
#
# Usage:
#   service = InboxMigrations::MigrateConversationsService.new(inbox_migration)
#   service.execute!
#
class InboxMigrations::MigrateConversationsService
  class MigrationError < StandardError; end

  BATCH_SIZE = 500

  attr_reader :migration, :source_inbox, :destination_inbox

  def initialize(inbox_migration)
    @migration = inbox_migration
    @source_inbox = inbox_migration.source_inbox
    @destination_inbox = inbox_migration.destination_inbox
  end

  def execute!
    validate_migration!
    calculate_and_store_counts!

    Rails.logger.info("[InboxMigration #{migration.id}] Starting migration: #{source_inbox.name} -> #{destination_inbox.name}")

    # Step 1: Build contact merge mapping (source_id conflicts)
    contact_merge_map = build_contact_merge_map

    # Step 2: Migrate contact_inboxes (move or merge)
    migrate_contact_inboxes!(contact_merge_map)

    # Step 3: Migrate conversations (update inbox_id and remap contact references)
    migrate_conversations!(contact_merge_map)

    # Step 4: Migrate messages
    migrate_messages!

    # Step 5: Migrate reporting events (for analytics/statistics)
    migrate_reporting_events!

    # Step 6: Cleanup orphaned source contact_inboxes
    cleanup_orphaned_contact_inboxes!

    Rails.logger.info("[InboxMigration #{migration.id}] Migration completed successfully")
  end

  private

  def validate_migration!
    raise MigrationError, 'Migration is not in running state' unless migration.running?
    raise MigrationError, 'Source inbox not found' unless source_inbox
    raise MigrationError, 'Destination inbox not found' unless destination_inbox
    raise MigrationError, 'Inboxes must be in the same account' unless source_inbox.account_id == destination_inbox.account_id
  end

  def calculate_and_store_counts!
    conversations_count = source_inbox.conversations.count
    messages_count = Message.where(inbox_id: source_inbox.id).count
    attachments_count = Attachment.joins(message: :conversation)
                                  .where(conversations: { inbox_id: source_inbox.id }).count
    contact_inboxes_count = ContactInbox.where(inbox_id: source_inbox.id).count

    migration.update_counts!(
      conversations: conversations_count,
      messages: messages_count,
      attachments: attachments_count,
      contact_inboxes: contact_inboxes_count
    )

    Rails.logger.info(
      "[InboxMigration #{migration.id}] Counts: " \
      "conversations=#{conversations_count}, messages=#{messages_count}, " \
      "attachments=#{attachments_count}, contact_inboxes=#{contact_inboxes_count}"
    )
  end

  # Build a map of source_id -> { source_contact_inbox, dest_contact_inbox, canonical_contact_id }
  # For conflicting source_ids, we'll use the destination's contact as canonical
  def build_contact_merge_map
    source_contact_inboxes = ContactInbox.where(inbox_id: source_inbox.id).index_by(&:source_id)
    dest_contact_inboxes = ContactInbox.where(inbox_id: destination_inbox.id).index_by(&:source_id)

    merge_map = {}

    source_contact_inboxes.each do |source_id, source_ci|
      dest_ci = dest_contact_inboxes[source_id]

      merge_map[source_id] = if dest_ci
                               # Conflict: same source_id exists in both inboxes
                               # Use destination contact as canonical, conversations will be remapped
                               {
                                 source_contact_inbox: source_ci,
                                 dest_contact_inbox: dest_ci,
                                 canonical_contact_id: dest_ci.contact_id,
                                 canonical_contact_inbox_id: dest_ci.id,
                                 needs_merge: true
                               }
                             else
                               # No conflict: just move the contact_inbox to destination
                               {
                                 source_contact_inbox: source_ci,
                                 dest_contact_inbox: nil,
                                 canonical_contact_id: source_ci.contact_id,
                                 canonical_contact_inbox_id: source_ci.id, # Will be updated after move
                                 needs_merge: false
                               }
                             end
    end

    conflicts_count = merge_map.values.count { |v| v[:needs_merge] }
    Rails.logger.info("[InboxMigration #{migration.id}] Found #{conflicts_count} contact conflicts to merge")

    merge_map
  end

  def migrate_contact_inboxes!(contact_merge_map)
    Rails.logger.info("[InboxMigration #{migration.id}] Migrating contact_inboxes...")

    moved_count = 0
    merged_count = 0

    contact_merge_map.each_value do |mapping|
      if mapping[:needs_merge]
        # Contact collision - merge data from source contact into destination contact
        merge_contact_data!(
          source_contact: mapping[:source_contact_inbox].contact,
          destination_contact: mapping[:dest_contact_inbox].contact
        )
        merged_count += 1
      else
        # No conflict - move the contact_inbox to destination inbox
        # Use update_columns to bypass validations (source_id format may differ between channel types)
        contact_inbox = mapping[:source_contact_inbox]
        contact_inbox.update_columns(inbox_id: destination_inbox.id)
        moved_count += 1
      end
    end

    migration.increment_progress!(contact_inboxes: moved_count, contacts_merged: merged_count)

    Rails.logger.info(
      "[InboxMigration #{migration.id}] Contact inboxes: moved=#{moved_count}, will_merge=#{merged_count}"
    )
  end

  # Merge contact data from source into destination without losing information
  # - Custom attributes: source values merged in, destination takes precedence for conflicts
  # - Notes: moved from source to destination
  # - Labels: added from source to destination (union)
  def merge_contact_data!(source_contact:, destination_contact:)
    return if source_contact.id == destination_contact.id

    Rails.logger.info(
      "[InboxMigration #{migration.id}] Merging contact #{source_contact.id} into #{destination_contact.id}"
    )

    # Merge custom_attributes (source values as base, destination overwrites)
    source_attrs = source_contact.custom_attributes || {}
    dest_attrs = destination_contact.custom_attributes || {}
    merged_attrs = source_attrs.merge(dest_attrs) # destination takes precedence
    destination_contact.update!(custom_attributes: merged_attrs) if merged_attrs != dest_attrs

    # Move notes from source to destination
    notes_moved = source_contact.notes.count
    source_contact.notes.update_all(contact_id: destination_contact.id)

    # Merge labels (union of both)
    source_labels = source_contact.labels.pluck(:title)
    if source_labels.any?
      existing_labels = destination_contact.labels.pluck(:title)
      new_labels = source_labels - existing_labels
      destination_contact.add_labels(new_labels) if new_labels.any?
    end

    Rails.logger.info(
      "[InboxMigration #{migration.id}] Merged contact data: " \
      "custom_attrs=#{source_attrs.keys.size}->#{merged_attrs.keys.size}, " \
      "notes_moved=#{notes_moved}, labels_added=#{source_labels.size}"
    )
  end

  def migrate_conversations!(contact_merge_map)
    Rails.logger.info("[InboxMigration #{migration.id}] Migrating conversations...")

    # Build lookup: source_contact_inbox_id -> new values
    contact_inbox_remap = {}
    contact_merge_map.each_value do |mapping|
      source_ci = mapping[:source_contact_inbox]
      contact_inbox_remap[source_ci.id] = {
        new_contact_id: mapping[:canonical_contact_id],
        new_contact_inbox_id: mapping[:canonical_contact_inbox_id]
      }
    end

    # Process conversations in batches
    conversation_ids = source_inbox.conversations.pluck(:id)
    total_moved = 0

    conversation_ids.each_slice(BATCH_SIZE) do |batch_ids|
      ActiveRecord::Base.transaction do
        Conversation.where(id: batch_ids).find_each do |conversation|
          remap = contact_inbox_remap[conversation.contact_inbox_id]

          update_attrs = { inbox_id: destination_inbox.id }

          # Always remap contact references if there's a mapping (merge case)
          # This ensures contact_inbox_id is updated even if contact_id stays the same
          if remap
            update_attrs[:contact_id] = remap[:new_contact_id]
            update_attrs[:contact_inbox_id] = remap[:new_contact_inbox_id]
          end

          conversation.update_columns(update_attrs)
          total_moved += 1
        end
      end

      migration.increment_progress!(conversations: batch_ids.size)
      Rails.logger.info("[InboxMigration #{migration.id}] Migrated #{total_moved}/#{conversation_ids.size} conversations")
    end
  end

  def migrate_messages!
    Rails.logger.info("[InboxMigration #{migration.id}] Migrating messages...")

    # Process messages in batches
    # Note: We use update_all for efficiency since we're just changing inbox_id
    message_ids = Message.where(inbox_id: source_inbox.id).pluck(:id)
    total_moved = 0

    message_ids.each_slice(BATCH_SIZE) do |batch_ids|
      moved = Message.where(id: batch_ids).update_all(inbox_id: destination_inbox.id)
      total_moved += moved

      migration.increment_progress!(messages: moved)
      Rails.logger.info("[InboxMigration #{migration.id}] Migrated #{total_moved}/#{message_ids.size} messages")
    end

    # Attachments don't have inbox_id - they're linked to messages
    # Count them for verification
    attachments_count = Attachment.joins(message: :conversation)
                                  .where(conversations: { inbox_id: destination_inbox.id })
                                  .count
    migration.update!(attachments_moved: attachments_count)
  end

  def migrate_reporting_events!
    Rails.logger.info("[InboxMigration #{migration.id}] Migrating reporting events...")

    # ReportingEvents store analytics data (first response time, resolution time, etc.)
    # Move them to preserve historical statistics
    events_count = ReportingEvent.where(inbox_id: source_inbox.id).count
    moved = ReportingEvent.where(inbox_id: source_inbox.id).update_all(inbox_id: destination_inbox.id)

    Rails.logger.info("[InboxMigration #{migration.id}] Migrated #{moved}/#{events_count} reporting events")
  end

  def cleanup_orphaned_contact_inboxes!
    Rails.logger.info("[InboxMigration #{migration.id}] Cleaning up orphaned contact_inboxes...")

    # Find contact_inboxes in source inbox that no longer have any conversations
    orphaned = ContactInbox.where(inbox_id: source_inbox.id)
                           .where.missing(:conversations)

    orphan_count = orphaned.count
    orphaned.destroy_all

    Rails.logger.info("[InboxMigration #{migration.id}] Deleted #{orphan_count} orphaned contact_inboxes")
  end
end
