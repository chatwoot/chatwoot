#!/usr/bin/env bash
# move_inbox_standalone.sh — Standalone inbox migration tool for Chatwoot
#
# Moves an inbox (and all associated records) between Chatwoot accounts by
# connecting directly to your Chatwoot database.
#
# Setup:
#   wget https://raw.githubusercontent.com/chatwoot/chatwoot/develop/script/move_inbox_standalone.sh
#   chmod +x move_inbox_standalone.sh
#
#   # Create .env in the same folder:
#   echo 'DATABASE_URL=postgres://user:pass@host:5432/chatwoot_production' > .env
#
#   # Optionally pin a Chatwoot version (default: develop):
#   echo 'CHATWOOT_VERSION=v3.14.0' >> .env
#
# Usage:
#   ./move_inbox_standalone.sh
#
# What happens:
#   1. Reads DATABASE_URL from .env
#   2. Clones the Chatwoot repo (shallow, cached for re-use)
#   3. Installs Ruby dependencies (one-time, cached)
#   4. Boots a minimal Rails environment
#   5. Runs the interactive inbox migration (dry-run first, then confirm)
#
# Prerequisites:
#   - Ruby (matching Chatwoot's .ruby-version, e.g. 3.3.x)
#   - Bundler (gem install bundler)
#   - Git
#   - PostgreSQL client libs (libpq-dev / postgresql-devel)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHATWOOT_DIR="$SCRIPT_DIR/.chatwoot_repo"
ENV_FILE="$SCRIPT_DIR/.env"

# -- Colors ----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}==>${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# -- Step 1: Read .env -----------------------------------------------------
info "Reading configuration from ${BOLD}.env${NC}"

if [[ ! -f "$ENV_FILE" ]]; then
  cat <<'HELP'
No .env file found. Create one in the same directory as this script:

  DATABASE_URL=postgres://user:pass@host:5432/chatwoot_production

Optional settings:
  CHATWOOT_VERSION=v3.14.0   # Git tag/branch (default: develop)
  POSTGRES_STATEMENT_TIMEOUT=60s
HELP
  error ".env file not found at $ENV_FILE"
fi

# Parse .env safely (skip comments, blank lines, export each var)
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"          # strip inline comments
  line="${line#"${line%%[![:space:]]*}"}"  # trim leading whitespace
  line="${line%"${line##*[![:space:]]}"}"  # trim trailing whitespace
  [[ -z "$line" ]] && continue
  export "$line"
done < "$ENV_FILE"

if [[ -z "${DATABASE_URL:-}" ]]; then
  error "DATABASE_URL not set in .env"
fi

CHATWOOT_VERSION="${CHATWOOT_VERSION:-develop}"
info "Database: ${BOLD}$(echo "$DATABASE_URL" | sed -E 's|://[^@]*@|://***@|')${NC}"
info "Chatwoot version: ${BOLD}$CHATWOOT_VERSION${NC}"

# -- Step 2: Check prerequisites -------------------------------------------
info "Checking prerequisites"

for cmd in ruby gem git; do
  command -v "$cmd" >/dev/null 2>&1 || error "'$cmd' is required but not found in PATH"
done

# Check bundler
if ! gem list bundler -i >/dev/null 2>&1; then
  warn "Bundler not found — installing..."
  gem install bundler --no-document
fi

echo "  Ruby:    $(ruby --version)"
echo "  Bundler: $(bundle --version)"
echo "  Git:     $(git --version)"

# -- Step 3: Clone / update Chatwoot repo ----------------------------------
if [[ -d "$CHATWOOT_DIR/.git" ]]; then
  info "Updating existing Chatwoot clone"
  cd "$CHATWOOT_DIR"
  # Fetch the desired ref
  git fetch --depth 1 origin "$CHATWOOT_VERSION" 2>/dev/null || git fetch --depth 1 origin
  git checkout FETCH_HEAD --force 2>/dev/null || git checkout "$CHATWOOT_VERSION" --force 2>/dev/null || true
  cd "$SCRIPT_DIR"
else
  info "Cloning Chatwoot repo (shallow clone, branch: $CHATWOOT_VERSION)..."
  git clone --depth 1 --branch "$CHATWOOT_VERSION" \
    https://github.com/chatwoot/chatwoot.git "$CHATWOOT_DIR" 2>&1 | tail -2
fi

# -- Step 4: Write migration files into the clone --------------------------
info "Installing migration scripts"

cat > "$CHATWOOT_DIR/script/move_inbox.rb" << 'RUBY_SERVICE'
# frozen_string_literal: true

# Moves a single inbox (any channel type) and all records attached to that inbox
# from one Chatwoot account to another.
#
# What is migrated:
# - Source inbox record and channel config
# - Conversations in the inbox, along with their contact + contact_inbox mapping
# - Dependent records (messages, attachments, notes, csat responses, mentions, events)
# - Custom attribute definitions are copied only when missing in destination
#
# What is cleaned up (deleted):
# - Notification rows for the migrated conversations
# - ConversationParticipant rows (reference source-account users)
# - AppliedSla / SlaEvent rows (enterprise, account-scoped)
# - InboxMember rows (reference source-account agents)
# - AgentBotInbox rows
# - Inbox-scoped webhooks and integration hooks
# - Campaigns associated with the inbox
#
# Validation is strict:
# - Destination account must be empty for operational data (excluding agents/custom attrs)
# - All source contacts participating in the moved inbox must not have conversations
#   in any other inbox
# - Destination must be different from source
#
# Caveats:
# - Contacts are re-owned by destination account (existing contact records are moved,
#   not recreated).
# - Account users (agents/admins) from the source account are copied into the
#   destination account so that assignee_id is retained on conversations.
# - Cross-references that are account-specific are cleared on conversation rows:
#   team_id, assignee_agent_bot_id, campaign_id, sla_policy_id, cached_label_list.
# - SLA policies / enterprise SLA rows are not migrated.
# - Custom attribute definitions are copied only when missing in destination and
#   are skipped if they collide with standard attributes.

# rubocop:disable Metrics/ClassLength
# rubocop:disable Rails/SkipsModelValidations
class Inboxes::MoveInboxToAccountService
  CUSTOM_ATTRIBUTE_MODELS = %w[
    conversation_attribute
    contact_attribute
  ].freeze
  ERROR_PREFIX = 'Inbox migration validation failed'
  RESERVED_CUSTOM_ATTRIBUTE_KEYS = {
    conversation_attribute: CustomAttributeDefinition::STANDARD_ATTRIBUTES[:conversation],
    contact_attribute: CustomAttributeDefinition::STANDARD_ATTRIBUTES[:contact]
  }.freeze

  class << self
    # rubocop:disable Metrics/ParameterLists
    def call(source_account_id:, source_inbox_id:, destination_account_id:, dry_run: true, batch_size: 100, logger: Logger.new(File::NULL))
      new(
        source_account_id: source_account_id,
        source_inbox_id: source_inbox_id,
        destination_account_id: destination_account_id,
        dry_run: dry_run,
        batch_size: batch_size,
        logger: logger
      ).perform
    end
    # rubocop:enable Metrics/ParameterLists
  end

  # rubocop:disable Metrics/ParameterLists
  def initialize(source_account_id:, source_inbox_id:, destination_account_id:, dry_run: true, batch_size: 100, logger: Logger.new(File::NULL))
    @source_account_id = source_account_id
    @source_inbox_id = source_inbox_id
    @destination_account_id = destination_account_id
    @dry_run = dry_run
    @batch_size = batch_size
    @logger = logger
    @summary = nil
    @prepared = false
    @source_to_destination_contact = {}
    @destination_contact_inboxes_by_source_id = {}
  end
  # rubocop:enable Metrics/ParameterLists

  def perform
    run(raise_on_validation: false)
  end

  def perform!
    run(raise_on_validation: true)
  end

  def summary
    prepare_summary
    @summary
  end

  private

  attr_reader :dry_run

  # rubocop:disable Metrics/MethodLength
  def run(raise_on_validation: false)
    prepare_summary

    if dry_run
      @summary[:status] = :dry_run
      return @summary
    end

    if @summary[:validation_errors].present?
      message = "#{ERROR_PREFIX}: #{@summary[:validation_errors].join(', ')}"
      return @summary if raise_on_validation == false

      raise ArgumentError, message
    end

    execute_migration!
    @summary[:status] = :applied
    @summary
  rescue StandardError => e
    @summary[:status] = :failed
    @summary[:error] = {
      class: e.class.name,
      message: e.message
    }
    raise e if raise_on_validation

    @summary
  end
  # rubocop:enable Metrics/MethodLength

  def execute_migration!
    ActiveRecord::Base.transaction do
      copy_custom_attribute_definitions!
      copy_labels!
      move_inbox_and_channel_config!
      copy_account_users!
      move_conversations!
      update_display_id_sequence!
      move_related_records!
      cleanup_orphaned_records!
    end
  end

  def prepare_summary
    return if @prepared

    load_source_and_destination
    build_scopes!
    validate_inputs
    build_preview!
    @prepared = true
  end

  # rubocop:disable Metrics/MethodLength
  def build_preview!
    @summary = {
      source_account_id: @source_account_id,
      source_inbox_id: @source_inbox_id,
      destination_account_id: @destination_account_id,
      dry_run: @dry_run,
      batch_size: @batch_size,
      status: :unknown,
      validation_errors: @validation_errors,
      will: {},
      moved: {
        labels_copied: 0,
        account_users_copied: 0,
        conversations: 0,
        contacts: 0,
        contacts_duplicated: 0,
        contact_inboxes: 0,
        messages: 0,
        attachments: 0,
        notes: 0,
        csat_survey_responses: 0,
        mentions: 0,
        reporting_events: 0,
        conversation_participants: 0,
        inbox_members: 0,
        notifications_deleted: 0,
        applied_slas_deleted: 0,
        sla_events_deleted: 0,
        agent_bot_inboxes_deleted: 0,
        inbox_webhooks_deleted: 0,
        inbox_hooks_deleted: 0,
        campaigns_deleted: 0
      },
      custom_attribute_definitions: {
        source_total: 0,
        to_create: 0,
        skipped_existing: 0,
        skipped_reserved: 0
      }
    }

    return if @summary[:validation_errors].present?

    build_custom_attribute_migration_plan!
    build_preview_counts!
  end
  # rubocop:enable Metrics/MethodLength

  def build_scopes!
    conversation_scope = source_inbox_conversations_scope

    @conversation_ids = conversation_scope.pluck(:id)
    @source_contact_ids = conversation_scope.pluck(:contact_id).uniq.compact
    @source_contact_inbox_ids = conversation_scope.pluck(:contact_inbox_id).uniq.compact
    @source_contacts_with_other_inbox_conversations = source_contact_ids_in_other_inboxes

    @source_contacts = Contact.where(id: @source_contact_ids).index_by(&:id)
    @source_contact_inboxes = ContactInbox.where(id: @source_contact_inbox_ids).index_by(&:id)
    @source_custom_attribute_definitions = CustomAttributeDefinition.where(
      account_id: @source_account_id,
      attribute_model: CUSTOM_ATTRIBUTE_MODELS
    ).to_a
  end

  def source_inbox_conversations_scope
    @source_inbox_conversations_scope ||= Conversation.where(
      account_id: @source_account_id,
      inbox_id: @source_inbox_id
    )
  end

  def source_contact_ids_in_other_inboxes
    return [] if @source_contact_ids.blank?

    Conversation.where(
      account_id: @source_account_id,
      contact_id: @source_contact_ids
    )
                .where.not(inbox_id: @source_inbox_id)
                .pluck(:contact_id)
                .uniq
                .compact
  end

  def build_custom_attribute_migration_plan!
    @summary[:custom_attribute_definitions][:source_total] = @source_custom_attribute_definitions.size

    return if @source_custom_attribute_definitions.empty?

    destination_keys = CustomAttributeDefinition.where(
      account_id: @destination_account_id,
      attribute_model: CUSTOM_ATTRIBUTE_MODELS
    )
    destination_pairs = destination_keys.pluck(:attribute_model, :attribute_key)

    @source_custom_attribute_definitions.each do |definition|
      if destination_pairs.include?([definition.attribute_model, definition.attribute_key])
        @summary[:custom_attribute_definitions][:skipped_existing] += 1
        next
      end

      if reserved_custom_attribute?(definition)
        @summary[:custom_attribute_definitions][:skipped_reserved] += 1
        next
      end

      @summary[:custom_attribute_definitions][:to_create] += 1
    end
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def build_preview_counts!
    messages_scope = Message.where(conversation_id: @conversation_ids)
    contact_scope_ids = @source_contact_ids

    @summary[:will][:inbox] = {
      source_name: @source_inbox&.name,
      channel_type: @source_inbox&.channel_type,
      destination_account_name: @destination_account&.name
    }
    @summary[:will][:labels] = Label.where(account_id: @source_account_id).count
    @summary[:will][:account_users] = AccountUser.where(account_id: @source_account_id).count
    @summary[:will][:conversations] = @conversation_ids.size
    @summary[:will][:contacts] = contact_scope_ids.size
    @summary[:will][:contacts_to_duplicate] = build_contacts_to_duplicate_list
    @summary[:will][:contact_inboxes] = @source_contact_inbox_ids.size
    @summary[:will][:messages] = messages_scope.count
    @summary[:will][:attachments] = Attachment.joins(:message)
                                              .where(messages: { conversation_id: @conversation_ids })
                                              .count
    @summary[:will][:notes] = Note.where(contact_id: contact_scope_ids).count
    @summary[:will][:csat_survey_responses] = CsatSurveyResponse.where(conversation_id: @conversation_ids).count
    @summary[:will][:mentions] = Mention.where(conversation_id: @conversation_ids).count
    @summary[:will][:reporting_events] = ReportingEvent.where(conversation_id: @conversation_ids).count
    @summary[:will][:notifications] = Notification.where(primary_actor_type: 'Conversation', primary_actor_id: @conversation_ids).count
    @summary[:will][:conversation_participants] = ConversationParticipant.where(conversation_id: @conversation_ids).count
    @summary[:will][:inbox_members] = InboxMember.where(inbox_id: @source_inbox_id).count
    @summary[:will][:agent_bot_inboxes] = AgentBotInbox.where(inbox_id: @source_inbox_id).count
    @summary[:will][:inbox_webhooks] = Webhook.where(inbox_id: @source_inbox_id, webhook_type: :inbox_type).count
    @summary[:will][:inbox_hooks] = Integrations::Hook.where(inbox_id: @source_inbox_id, hook_type: :inbox).count
    @summary[:will][:campaigns] = Campaign.where(inbox_id: @source_inbox_id, account_id: @source_account_id).count

    build_enterprise_preview_counts!
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def build_contacts_to_duplicate_list
    return [] if @source_contacts_with_other_inbox_conversations.blank?

    Contact.where(id: @source_contacts_with_other_inbox_conversations).map do |contact|
      { id: contact.id, name: contact.name, email: contact.email, phone_number: contact.phone_number }
    end
  end

  def build_enterprise_preview_counts!
    applied_sla_klass = 'AppliedSla'.safe_constantize
    sla_event_klass = 'SlaEvent'.safe_constantize

    @summary[:will][:applied_slas] = applied_sla_klass ? applied_sla_klass.where(conversation_id: @conversation_ids).count : 0
    @summary[:will][:sla_events] = sla_event_klass ? sla_event_klass.where(conversation_id: @conversation_ids).count : 0
  end

  def load_source_and_destination
    @validation_errors = []

    @source_account = Account.find_by(id: @source_account_id)
    @destination_account = Account.find_by(id: @destination_account_id)
    @source_inbox = Inbox.find_by(id: @source_inbox_id)
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def validate_inputs
    @validation_errors << "Source account ##{@source_account_id} not found" if @source_account.blank?
    @validation_errors << "Destination account ##{@destination_account_id} not found" if @destination_account.blank?
    return if @validation_errors.present?

    if @source_inbox.blank?
      @validation_errors << "Source inbox ##{@source_inbox_id} not found"
      return
    end

    @validation_errors << 'Destination account must be different from source account' if @source_account_id.to_i == @destination_account_id.to_i

    if @source_inbox.account_id != @source_account.id
      @validation_errors << "Source inbox ##{@source_inbox_id} does not belong to account ##{@source_account_id}"
    end

    return unless destination_not_empty?

    @validation_errors << "Destination account ##{@destination_account_id} is not empty: #{destination_occupancy_issues.join(', ')}"
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def destination_not_empty?
    destination_occupancy_issues.present?
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def destination_occupancy_issues
    @destination_occupancy_issues ||= [
      ('inboxes' if @destination_account.inboxes.exists?),
      ('conversations' if @destination_account.conversations.exists?),
      ('messages' if @destination_account.messages.exists?),
      ('contacts' if @destination_account.contacts.exists?),
      ('contact_inboxes' if contact_inboxes_exist_in_destination?),
      ('notes' if @destination_account.notes.exists?),
      ('campaigns' if @destination_account.campaigns.exists?)
    ].compact
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def contact_inboxes_exist_in_destination?
    ContactInbox.exists?(contact: @destination_account.contacts)
  end

  def copy_labels!
    source_labels = Label.where(account_id: @source_account_id)
    return if source_labels.empty?

    rows = source_labels.map do |label|
      {
        account_id: @destination_account_id,
        title: label.title,
        description: label.description,
        color: label.color,
        show_on_sidebar: label.show_on_sidebar,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    @logger.info "Copying #{rows.size} labels to destination account"
    result = Label.insert_all(rows, unique_by: %i[title account_id]) # rubocop:disable Rails/SkipsModelValidations
    @summary[:moved][:labels_copied] = result.count
  end

  def copy_account_users!
    source_account_users = AccountUser.where(account_id: @source_account_id)
    return if source_account_users.empty?

    rows = source_account_users.map do |au|
      {
        account_id: @destination_account_id,
        user_id: au.user_id,
        role: au.role,
        availability: AccountUser.availabilities[:offline],
        auto_offline: true,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    @logger.info "Copying #{rows.size} account users to destination account"
    result = AccountUser.insert_all(rows, unique_by: %i[account_id user_id]) # rubocop:disable Rails/SkipsModelValidations
    @summary[:moved][:account_users_copied] = result.count
  end

  def move_inbox_and_channel_config!
    @logger.info "Moving inbox ##{@source_inbox_id} and channel config to account ##{@destination_account_id}"
    @source_inbox.update_columns(account_id: @destination_account_id)
    @source_inbox.channel.update_columns(account_id: @destination_account_id)
  end

  def move_conversations!
    @logger.info "Moving #{@conversation_ids.size} conversations in batches of #{@batch_size}"
    source_inbox_conversations_scope
      .in_batches(of: @batch_size) do |conversation_batch|
      conversation_batch.each do |conversation|
        migrate_conversation!(conversation)
      end
      @logger.info "  Migrated #{@summary[:moved][:conversations]} conversations so far"
    end

    @summary[:moved][:contact_inboxes] = @source_contact_inbox_ids.size
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def migrate_conversation!(conversation)
    source_contact = @source_contacts[conversation.contact_id]

    raise "Source conversation ##{conversation.id} has missing contact reference" unless source_contact

    destination_contact = destination_contact_for(source_contact)

    update_attrs = {
      account_id: @destination_account_id,
      contact_id: destination_contact.id,
      team_id: nil,
      assignee_agent_bot_id: nil,
      campaign_id: nil,
      sla_policy_id: nil
    }

    # Only remap contact_inbox if the conversation has one
    if conversation.contact_inbox_id.present?
      source_contact_inbox = @source_contact_inboxes[conversation.contact_inbox_id]
      raise "Source conversation ##{conversation.id} has missing contact inbox reference" unless source_contact_inbox

      destination_contact_inbox = destination_contact_inbox_for(source_contact_inbox, destination_contact)
      update_attrs[:contact_inbox_id] = destination_contact_inbox.id
    end

    conversation.update_columns(update_attrs)

    source_contact_processed = source_contact_id_processed?(conversation.contact_id)
    @source_to_destination_contact[conversation.contact_id] = destination_contact
    @summary[:moved][:contacts] += 1 unless source_contact_processed
    @summary[:moved][:conversations] += 1
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def update_display_id_sequence!
    max_display_id = Conversation.where(account_id: @destination_account_id).maximum(:display_id) || 0
    return if max_display_id.zero?

    quoted_id = ActiveRecord::Base.connection.quote(@destination_account_id)
    ActiveRecord::Base.connection.execute("SELECT setval('conv_dpid_seq_' || #{quoted_id}, #{max_display_id})")
    @logger.info "Updated display_id sequence to #{max_display_id}"
  end

  def destination_contact_for(source_contact)
    return @source_to_destination_contact[source_contact.id] if source_contact_id_processed?(source_contact.id)

    if contact_needs_duplication?(source_contact.id)
      duplicate_contact(source_contact)
    else
      source_contact.update_columns(account_id: @destination_account_id)
      @source_to_destination_contact[source_contact.id] = source_contact
      source_contact
    end
  end

  def contact_needs_duplication?(contact_id)
    @source_contacts_with_other_inbox_conversations.include?(contact_id)
  end

  def duplicate_contact(source_contact)
    new_contact = source_contact.dup
    new_contact.account_id = @destination_account_id
    new_contact.company_id = nil
    new_contact.save!

    @source_to_destination_contact[source_contact.id] = new_contact
    @summary[:moved][:contacts_duplicated] += 1
    new_contact
  end

  def source_contact_id_processed?(source_contact_id)
    @source_to_destination_contact.key?(source_contact_id)
  end

  def destination_contact_inbox_for(source_contact_inbox, destination_contact)
    existing = @destination_contact_inboxes_by_source_id[source_contact_inbox.source_id]
    return existing if existing

    source_contact_inbox.update_columns(
      contact_id: destination_contact.id,
      inbox_id: @source_inbox.id
    )
    destination_inbox = source_contact_inbox

    @destination_contact_inboxes_by_source_id[source_contact_inbox.source_id] = destination_inbox

    destination_inbox
  end

  def move_related_records!
    @logger.info 'Moving messages and attachments'
    message_scope = Message.where(conversation_id: @conversation_ids)
    @summary[:moved][:messages] = message_scope.update_all(account_id: @destination_account_id)

    @summary[:moved][:attachments] = Attachment.where(message_id: message_scope.select(:id))
                                               .update_all(account_id: @destination_account_id)

    move_notes!
    move_csat_survey_responses!
    move_mentions!
    move_reporting_events!
  end

  def move_notes!
    @logger.info 'Moving notes'
    notes_scope = Note.where(contact_id: @source_contact_ids)
    @summary[:moved][:notes] = notes_scope.update_all(account_id: @destination_account_id, user_id: nil)
  end

  def move_csat_survey_responses!
    @logger.info 'Moving CSAT survey responses'
    csat_scope = CsatSurveyResponse.where(conversation_id: @conversation_ids)
    @summary[:moved][:csat_survey_responses] = csat_scope.update_all(account_id: @destination_account_id)
  end

  def move_mentions!
    @logger.info 'Moving mentions'
    @summary[:moved][:mentions] = Mention.where(conversation_id: @conversation_ids)
                                         .update_all(account_id: @destination_account_id)
  end

  def move_reporting_events!
    @logger.info 'Moving reporting events'
    @summary[:moved][:reporting_events] = ReportingEvent.where(conversation_id: @conversation_ids)
                                                        .update_all(account_id: @destination_account_id, user_id: nil)
  end

  # -- Cleanup methods for orphaned records --

  def cleanup_orphaned_records!
    @logger.info 'Cleaning up orphaned records'
    cleanup_notifications!
    migrate_conversation_participants!
    cleanup_sla_records!
    migrate_inbox_members!
    cleanup_agent_bot_inbox!
    cleanup_inbox_webhooks!
    cleanup_inbox_hooks!
    cleanup_campaigns!
  end

  def cleanup_notifications!
    @logger.info '  Deleting notifications for migrated conversations'
    notifications_scope = Notification.where(
      primary_actor_type: 'Conversation',
      primary_actor_id: @conversation_ids
    )
    @summary[:moved][:notifications_deleted] = notifications_scope.count
    notifications_scope.delete_all
  end

  def migrate_conversation_participants!
    @logger.info '  Migrating conversation participants'
    @summary[:moved][:conversation_participants] = ConversationParticipant
                                                     .where(conversation_id: @conversation_ids)
                                                     .update_all(account_id: @destination_account_id)
  end

  def cleanup_sla_records!
    applied_sla_klass = 'AppliedSla'.safe_constantize
    sla_event_klass = 'SlaEvent'.safe_constantize

    if sla_event_klass
      @logger.info '  Deleting SLA events'
      @summary[:moved][:sla_events_deleted] = sla_event_klass.where(conversation_id: @conversation_ids).delete_all
    end

    return unless applied_sla_klass

    @logger.info '  Deleting applied SLAs'
    @summary[:moved][:applied_slas_deleted] = applied_sla_klass.where(conversation_id: @conversation_ids).delete_all
  end

  def migrate_inbox_members!
    # InboxMember has no account_id — rows just reference inbox_id + user_id.
    # The inbox is already moved and users are copied, so these rows are valid as-is.
    @summary[:moved][:inbox_members] = InboxMember.where(inbox_id: @source_inbox_id).count
    @logger.info "  Retained #{@summary[:moved][:inbox_members]} inbox members"
  end

  def cleanup_agent_bot_inbox!
    @logger.info '  Deleting agent bot inbox associations'
    @summary[:moved][:agent_bot_inboxes_deleted] = AgentBotInbox.where(inbox_id: @source_inbox_id).delete_all
  end

  def cleanup_inbox_webhooks!
    @logger.info '  Deleting inbox-scoped webhooks'
    @summary[:moved][:inbox_webhooks_deleted] = Webhook.where(inbox_id: @source_inbox_id, webhook_type: :inbox_type).delete_all
  end

  def cleanup_inbox_hooks!
    @logger.info '  Deleting inbox-scoped integration hooks'
    @summary[:moved][:inbox_hooks_deleted] = Integrations::Hook.where(inbox_id: @source_inbox_id, hook_type: :inbox).delete_all
  end

  def cleanup_campaigns!
    @logger.info '  Deleting campaigns for inbox'
    @summary[:moved][:campaigns_deleted] = Campaign.where(inbox_id: @source_inbox_id, account_id: @destination_account_id).delete_all
  end

  def copy_custom_attribute_definitions!
    return if @source_custom_attribute_definitions.empty?

    @logger.info "Copying #{@summary[:custom_attribute_definitions][:to_create]} custom attribute definitions"

    @source_custom_attribute_definitions.each do |definition|
      next if custom_definition_exists?(definition)
      next if reserved_custom_attribute?(definition)

      destination_definition = definition.attributes.slice(
        'attribute_description',
        'attribute_display_name',
        'attribute_display_type',
        'attribute_key',
        'attribute_model',
        'attribute_values',
        'default_value',
        'regex_cue',
        'regex_pattern'
      )

      destination_definition['account_id'] = @destination_account_id
      CustomAttributeDefinition.create!(destination_definition)
    end
  end

  def custom_definition_exists?(definition)
    CustomAttributeDefinition.exists?(
      account_id: @destination_account_id,
      attribute_model: definition.attribute_model,
      attribute_key: definition.attribute_key
    )
  end

  def reserved_custom_attribute?(definition)
    RESERVED_CUSTOM_ATTRIBUTE_KEYS[definition.attribute_model.to_sym]&.include?(definition.attribute_key)
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Rails/SkipsModelValidations
RUBY_SERVICE

# Write the runner script (interactive flow, replaces the rake task)
cat > "$CHATWOOT_DIR/tmp/move_inbox_runner.rb" << 'RUBY_RUNNER'
# frozen_string_literal: true

require Rails.root.join('script/move_inbox')

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/ModuleLength, Style/FormatStringToken
module MoveInboxRunner
  def self.prompt(message)
    print "#{message}: "
    $stdin.gets.chomp
  end

  def self.run
    puts 'Move Inbox Between Accounts'
    puts '=' * 40

    source_account = collect_source_account
    inbox = collect_inbox(source_account)
    destination_account = collect_destination_account(source_account)

    puts "\nRunning dry-run..."
    result = Inboxes::MoveInboxToAccountService.call(
      source_account_id: source_account.id,
      source_inbox_id: inbox.id,
      destination_account_id: destination_account.id,
      dry_run: true
    )

    if result[:validation_errors].present?
      puts "\nValidation errors:"
      result[:validation_errors].each { |e| puts "  - #{e}" }
      abort "\nAborted due to validation errors."
    end

    print_preview(result)

    confirmation = prompt("\nProceed with migration? (y/N)")
    abort 'Migration cancelled.' unless confirmation.downcase == 'y'

    puts "\nExecuting migration..."
    logger = Logger.new($stdout)
    logger.formatter = proc { |_severity, _time, _progname, msg| "  #{msg}\n" }

    result = Inboxes::MoveInboxToAccountService.call(
      source_account_id: source_account.id,
      source_inbox_id: inbox.id,
      destination_account_id: destination_account.id,
      dry_run: false,
      logger: logger
    )

    if result[:status] == :failed
      puts "\nMigration FAILED (all changes rolled back)"
      puts "  Error: #{result[:error][:class]}: #{result[:error][:message]}"
    else
      puts "\nMigration complete!"
    end
    print_result(result)
  end

  def self.collect_source_account
    account_id = prompt("\nSource account ID")
    abort 'Error: Account ID is required' if account_id.blank?

    account = Account.find_by(id: account_id)
    abort "Error: Account ##{account_id} not found" unless account

    puts "  Account: #{account.name} (##{account.id})"
    account
  end

  def self.collect_inbox(account)
    inboxes = account.inboxes.includes(:channel).order(:id)

    abort "Error: Account ##{account.id} has no inboxes" if inboxes.empty?

    puts "\nInboxes in account ##{account.id}:"
    puts '  ID     Name                           Channel Type              Created'
    puts "  #{'-' * 80}"
    inboxes.each do |inbox|
      puts format('  %-6d %-30s %-25s %s', inbox.id, inbox.name.truncate(28), inbox.channel_type, inbox.created_at.to_date)
    end

    inbox_id = prompt("\nInbox ID to move")
    abort 'Error: Inbox ID is required' if inbox_id.blank?

    inbox = inboxes.find { |i| i.id == inbox_id.to_i }
    abort "Error: Inbox ##{inbox_id} not found in account ##{account.id}" unless inbox

    puts "  Selected: #{inbox.name} (#{inbox.channel_type})"
    inbox
  end

  def self.collect_destination_account(source_account)
    account_id = prompt("\nDestination account ID")
    abort 'Error: Account ID is required' if account_id.blank?

    abort 'Error: Destination must be different from source account' if account_id.to_i == source_account.id

    account = Account.find_by(id: account_id)
    abort "Error: Account ##{account_id} not found" unless account

    puts "  Account: #{account.name} (##{account.id})"
    account
  end

  def self.print_preview(result)
    will = result[:will]
    custom = result[:custom_attribute_definitions]

    puts "\nDry-run summary"
    puts '-' * 40

    inbox_info = will[:inbox] || {}
    puts "Inbox: #{inbox_info[:source_name]} (#{inbox_info[:channel_type]})"
    puts "Destination: #{inbox_info[:destination_account_name]}"

    puts "\nRecords to copy/migrate:"
    puts format('  %-30s %s', 'Labels', will[:labels])
    puts format('  %-30s %s', 'Account users', will[:account_users])
    puts format('  %-30s %s', 'Conversations', will[:conversations])
    puts format('  %-30s %s', 'Contacts', will[:contacts])
    print_contacts_to_duplicate(will[:contacts_to_duplicate])
    puts format('  %-30s %s', 'Contact inboxes', will[:contact_inboxes])
    puts format('  %-30s %s', 'Messages', will[:messages])
    puts format('  %-30s %s', 'Attachments', will[:attachments])
    puts format('  %-30s %s', 'Notes', will[:notes])
    puts format('  %-30s %s', 'CSAT responses', will[:csat_survey_responses])
    puts format('  %-30s %s', 'Mentions', will[:mentions])
    puts format('  %-30s %s', 'Reporting events', will[:reporting_events])
    puts format('  %-30s %s', 'Conversation participants', will[:conversation_participants])
    puts format('  %-30s %s', 'Inbox members', will[:inbox_members])

    puts "\nRecords to clean up (delete):"
    puts format('  %-30s %s', 'Notifications', will[:notifications])
    puts format('  %-30s %s', 'Applied SLAs', will[:applied_slas])
    puts format('  %-30s %s', 'SLA events', will[:sla_events])
    puts format('  %-30s %s', 'Agent bot inboxes', will[:agent_bot_inboxes])
    puts format('  %-30s %s', 'Inbox webhooks', will[:inbox_webhooks])
    puts format('  %-30s %s', 'Inbox hooks', will[:inbox_hooks])
    puts format('  %-30s %s', 'Campaigns', will[:campaigns])

    return if custom[:source_total].zero?

    puts "\nCustom attribute definitions:"
    puts format('  %-30s %s', 'Source total', custom[:source_total])
    puts format('  %-30s %s', 'To create', custom[:to_create])
    puts format('  %-30s %s', 'Skipped (existing)', custom[:skipped_existing])
    puts format('  %-30s %s', 'Skipped (reserved)', custom[:skipped_reserved])
  end

  def self.print_contacts_to_duplicate(contacts)
    return if contacts.blank?

    puts "\n  Contacts with conversations in other inboxes (will be duplicated):"
    puts format('    %-8s %-25s %-30s %s', 'ID', 'Name', 'Email', 'Phone')
    puts "    #{'-' * 75}"
    contacts.each do |c|
      puts format('    %-8s %-25s %-30s %s', c[:id], c[:name].to_s.truncate(23), c[:email].to_s.truncate(28), c[:phone_number])
    end
    puts ''
  end

  def self.print_result(result)
    moved = result[:moved]

    puts "\nFinal results (status: #{result[:status]})"
    puts '-' * 40

    puts 'Records migrated:'
    puts format('  %-30s %s', 'Labels copied', moved[:labels_copied])
    puts format('  %-30s %s', 'Account users copied', moved[:account_users_copied])
    puts format('  %-30s %s', 'Conversations', moved[:conversations])
    puts format('  %-30s %s', 'Contacts', moved[:contacts])
    puts format('  %-30s %s', 'Contacts duplicated', moved[:contacts_duplicated])
    puts format('  %-30s %s', 'Contact inboxes', moved[:contact_inboxes])
    puts format('  %-30s %s', 'Messages', moved[:messages])
    puts format('  %-30s %s', 'Attachments', moved[:attachments])
    puts format('  %-30s %s', 'Notes', moved[:notes])
    puts format('  %-30s %s', 'CSAT responses', moved[:csat_survey_responses])
    puts format('  %-30s %s', 'Mentions', moved[:mentions])
    puts format('  %-30s %s', 'Reporting events', moved[:reporting_events])
    puts format('  %-30s %s', 'Conversation participants', moved[:conversation_participants])
    puts format('  %-30s %s', 'Inbox members', moved[:inbox_members])

    puts "\nRecords cleaned up:"
    puts format('  %-30s %s', 'Notifications deleted', moved[:notifications_deleted])
    puts format('  %-30s %s', 'Applied SLAs deleted', moved[:applied_slas_deleted])
    puts format('  %-30s %s', 'SLA events deleted', moved[:sla_events_deleted])
    puts format('  %-30s %s', 'Agent bot inboxes deleted', moved[:agent_bot_inboxes_deleted])
    puts format('  %-30s %s', 'Inbox webhooks deleted', moved[:inbox_webhooks_deleted])
    puts format('  %-30s %s', 'Inbox hooks deleted', moved[:inbox_hooks_deleted])
    puts format('  %-30s %s', 'Campaigns deleted', moved[:campaigns_deleted])
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/ModuleLength, Style/FormatStringToken

MoveInboxRunner.run
RUBY_RUNNER

info "Migration scripts installed"

# -- Step 5: Bundle install -------------------------------------------------
info "Installing Ruby dependencies (this may take a few minutes on first run)..."
cd "$CHATWOOT_DIR"

# Configure bundler for local vendor path (keeps gems isolated)
bundle config set --local path 'vendor/bundle' 2>/dev/null
bundle config set --local without 'development test' 2>/dev/null
bundle config set --local jobs "$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)" 2>/dev/null

bundle install --quiet 2>&1 | tail -5
cd "$SCRIPT_DIR"

# -- Step 6: Run the migration ---------------------------------------------
info "Booting Chatwoot environment and starting migration\n"

cd "$CHATWOOT_DIR"
exec env \
  DATABASE_URL="$DATABASE_URL" \
  SECRET_KEY_BASE="standalone_migration_tool_dummy_key_not_used_for_crypto_00000000000000000000000" \
  REDIS_URL="${REDIS_URL:-redis://localhost:6379}" \
  RAILS_ENV=production \
  RAILS_LOG_TO_STDOUT=false \
  DISABLE_TELEMETRY=true \
  bundle exec rails runner tmp/move_inbox_runner.rb
