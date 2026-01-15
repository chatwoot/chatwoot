# frozen_string_literal: true

# Api::V1::Accounts::InboxMigrationsController
#
# Handles inbox conversation migrations for API and WhatsApp-like inboxes.
# Allows moving conversations, messages, attachments, and contacts from
# one inbox to another within the same account.
#
# Available for:
# - All API channel inboxes (Channel::Api)
# - Native WhatsApp inboxes (Channel::Whatsapp)
# - Twilio WhatsApp inboxes (Channel::TwilioSms with medium: whatsapp)
#
class Api::V1::Accounts::InboxMigrationsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization!
  before_action :fetch_source_inbox
  before_action :validate_whatsapp_inbox!
  before_action :fetch_migration, only: [:show, :cancel]

  # GET /api/v1/accounts/:account_id/inboxes/:inbox_id/migrations
  # List migrations for this inbox (as source)
  def index
    @migrations = @inbox.inbox_migrations_as_source.recent.limit(20)
    render json: migrations_response(@migrations)
  end

  # GET /api/v1/accounts/:account_id/inboxes/:inbox_id/migrations/:id
  # Show migration status and progress
  def show
    render json: migration_response(@migration)
  end

  # POST /api/v1/accounts/:account_id/inboxes/:inbox_id/migrations
  # Create a new migration to move conversations to destination inbox
  def create
    destination_inbox = Current.account.inboxes.find(migration_params[:destination_inbox_id])

    unless InboxMigration.whatsapp_like_inbox?(destination_inbox)
      render json: { error: 'Destination inbox must be a WhatsApp-like inbox' }, status: :unprocessable_entity
      return
    end

    @migration = InboxMigration.new(
      account: Current.account,
      source_inbox: @inbox,
      destination_inbox: destination_inbox,
      user: Current.user
    )

    if @migration.save
      # Enqueue the migration job
      InboxMigrations::PerformJob.perform_later(@migration.id)
      render json: migration_response(@migration), status: :created
    else
      render json: { errors: @migration.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/accounts/:account_id/inboxes/:inbox_id/migrations/:id/cancel
  # Cancel a queued migration (cannot cancel running migrations)
  def cancel
    unless @migration.queued?
      render json: { error: 'Only queued migrations can be cancelled' }, status: :unprocessable_entity
      return
    end

    @migration.mark_cancelled!
    render json: migration_response(@migration)
  end

  # GET /api/v1/accounts/:account_id/inboxes/:inbox_id/migrations/preview
  # Get counts for what would be migrated
  def preview
    destination_inbox_id = params[:destination_inbox_id]

    if destination_inbox_id.blank?
      render json: { error: 'destination_inbox_id is required' }, status: :unprocessable_entity
      return
    end

    destination_inbox = Current.account.inboxes.find(destination_inbox_id)

    unless InboxMigration.whatsapp_like_inbox?(destination_inbox)
      render json: { error: 'Destination inbox must be a WhatsApp-like inbox' }, status: :unprocessable_entity
      return
    end

    render json: preview_response(@inbox, destination_inbox)
  end

  # GET /api/v1/accounts/:account_id/inboxes/:inbox_id/migrations/eligible_destinations
  # List inboxes that can be migration destinations
  def eligible_destinations
    eligible = Current.account.inboxes
                      .where.not(id: @inbox.id)
                      .select { |inbox| InboxMigration.whatsapp_like_inbox?(inbox) }

    render json: {
      inboxes: eligible.map do |inbox|
        {
          id: inbox.id,
          name: inbox.name,
          channel_type: inbox.channel_type,
          conversations_count: inbox.conversations.count
        }
      end
    }
  end

  private

  def check_admin_authorization!
    raise Pundit::NotAuthorizedError unless Current.user&.administrator?
  end

  def fetch_source_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def validate_whatsapp_inbox!
    return if InboxMigration.whatsapp_like_inbox?(@inbox)

    render json: {
      error: 'Migration is only available for WhatsApp-like inboxes (Evolution API, WhatsApp, or Twilio WhatsApp)'
    }, status: :forbidden
  end

  def fetch_migration
    @migration = @inbox.inbox_migrations_as_source.find(params[:id])
  end

  def migration_params
    params.require(:inbox_migration).permit(:destination_inbox_id)
  end

  def migration_response(migration)
    {
      id: migration.id,
      status: migration.status,
      source_inbox: inbox_summary(migration.source_inbox),
      destination_inbox: inbox_summary(migration.destination_inbox),
      progress: {
        percentage: migration.progress_percentage,
        conversations: { total: migration.conversations_count, moved: migration.conversations_moved },
        messages: { total: migration.messages_count, moved: migration.messages_moved },
        attachments: { total: migration.attachments_count, moved: migration.attachments_moved },
        contact_inboxes: { total: migration.contact_inboxes_count, moved: migration.contact_inboxes_moved },
        contacts_merged: migration.contacts_merged
      },
      timing: {
        created_at: migration.created_at,
        started_at: migration.started_at,
        completed_at: migration.completed_at,
        duration_seconds: migration.duration_seconds
      },
      error: migration.error_message,
      initiated_by: migration.user&.name
    }
  end

  def migrations_response(migrations)
    {
      migrations: migrations.map { |m| migration_response(m) }
    }
  end

  def preview_response(source_inbox, destination_inbox)
    source_contact_inbox_ids = ContactInbox.where(inbox_id: source_inbox.id).pluck(:source_id)
    dest_contact_inbox_ids = ContactInbox.where(inbox_id: destination_inbox.id).pluck(:source_id)
    conflicts = source_contact_inbox_ids & dest_contact_inbox_ids

    {
      source_inbox: inbox_summary(source_inbox),
      destination_inbox: inbox_summary(destination_inbox),
      counts: {
        conversations: source_inbox.conversations.count,
        messages: Message.where(inbox_id: source_inbox.id).count,
        attachments: Attachment.joins(message: :conversation).where(conversations: { inbox_id: source_inbox.id }).count,
        contact_inboxes: source_contact_inbox_ids.count
      },
      conflicts: {
        overlapping_contacts: conflicts.count,
        will_be_merged: conflicts.count
      },
      warnings: build_warnings(source_inbox, conflicts)
    }
  end

  def inbox_summary(inbox)
    {
      id: inbox.id,
      name: inbox.name,
      channel_type: inbox.channel_type
    }
  end

  def build_warnings(source_inbox, conflicts)
    warnings = []

    warnings << { key: 'LARGE_MIGRATION' } if source_inbox.conversations.count > 1000

    warnings << { key: 'CONTACTS_WILL_MERGE', params: { count: conflicts.count } } if conflicts.any?

    warnings << { key: 'CANNOT_BE_UNDONE' }

    warnings
  end
end
