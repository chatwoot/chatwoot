# frozen_string_literal: true

# Usage:
#   bundle exec rails runner script/migrate_whatsapp_inbox_account.rb \
#     --source-inbox-id=123 --target-account-id=456 --mode=dry-run
#
# Notes:
# - v1 is limited to Channel::Whatsapp inboxes.
# - Stop workers / Sidekiq during the migration window.
# - Run dry-run first and review blockers/warnings before execute.

require 'optparse'
require 'json'
require 'fileutils'

# One-off operational script. Intentionally bypasses validations/callbacks via
# update_columns/update_all (Rails/SkipsModelValidations) and groups orchestration
# into a single class with long methods for readability during execution review.
# rubocop:disable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
# rubocop:disable Rails/SkipsModelValidations, Layout/LineLength
class WhatsappInboxAccountMigration
  MODES = %w[dry-run execute].freeze

  MigrationBlockedError = Class.new(StandardError)

  def self.run(argv)
    new(argv).run
  end

  def initialize(argv)
    @options = { mode: 'dry-run' }
    parse_options!(argv)
    validate_options!
    load_records!
  end

  def run
    print_header
    summary = build_summary
    print_summary(summary)
    raise MigrationBlockedError, 'Dry run reported blockers. Resolve them before execute.' if summary[:blockers].any?
    return unless execute?

    snapshot_path = dump_pre_migration_snapshot!(summary)
    execute_migration!(summary)
    puts ''
    puts 'Migration completed successfully.'
    puts "Moved inbox #{source_inbox.id} from account #{source_account.id} to account #{target_account.id}."
    puts "Pre-migration snapshot: #{snapshot_path}"
  rescue OptionParser::ParseError, MigrationBlockedError => e
    warn "ERROR: #{e.message}"
    exit 1
  end

  private

  attr_reader :options, :source_inbox, :source_account, :target_account

  def parse_options!(argv)
    OptionParser.new do |parser|
      parser.banner = 'Usage: rails runner script/migrate_whatsapp_inbox_account.rb --source-inbox-id=ID --target-account-id=ID --mode=dry-run|execute'

      parser.on('--source-inbox-id=ID', Integer, 'Source WhatsApp inbox id') { |value| options[:source_inbox_id] = value }
      parser.on('--target-account-id=ID', Integer, 'Target account id') { |value| options[:target_account_id] = value }
      parser.on('--mode=MODE', String, "Mode: #{MODES.join(', ')}") { |value| options[:mode] = value }
      parser.on('--snapshot-path=PATH', String, 'Override pre-migration snapshot file path (execute mode only)') { |value| options[:snapshot_path] = value }
      parser.on('-h', '--help', 'Show help') do
        puts parser
        exit 0
      end
    end.parse!(argv)
  end

  def validate_options!
    raise OptionParser::ParseError, '--source-inbox-id is required' if options[:source_inbox_id].blank?
    raise OptionParser::ParseError, '--target-account-id is required' if options[:target_account_id].blank?
    raise OptionParser::ParseError, "--mode must be one of: #{MODES.join(', ')}" unless MODES.include?(options[:mode])
  end

  def load_records!
    @source_inbox = Inbox.find(options[:source_inbox_id])
    @source_account = source_inbox.account
    @target_account = Account.find(options[:target_account_id])
  end

  def execute?
    options[:mode] == 'execute'
  end

  def build_summary
    conversation_scope = Conversation.where(inbox_id: source_inbox.id)
    message_scope = Message.where(conversation_id: conversation_scope.select(:id))
    source_contact_ids = ContactInbox.where(inbox_id: source_inbox.id).distinct.pluck(:contact_id)
    source_contacts = Contact.where(id: source_contact_ids).order(:id).to_a
    contact_plan = build_contact_plan(source_contacts)
    label_titles = migrated_label_titles(conversation_scope)

    blockers = []
    warnings = []

    blockers << 'Source inbox must be a Channel::Whatsapp inbox.' unless source_inbox.channel_type == 'Channel::Whatsapp'
    blockers << 'Source inbox channel must be Channel::Whatsapp.' unless source_inbox.channel.is_a?(Channel::Whatsapp)
    blockers << 'Source and target accounts must be different.' if source_account.id == target_account.id
    blockers << 'Inbox account_id does not match channel account_id.' unless source_inbox.channel.account_id == source_account.id
    blockers << 'Inbox has inbox-level webhooks. v1 aborts instead of migrating webhook configuration.' if source_inbox.webhooks.exists?
    blockers << 'Inbox has integrations hooks. v1 aborts instead of migrating integrations.' if source_inbox.hooks.exists?
    blockers << 'Inbox has campaigns. v1 aborts instead of migrating campaign configuration.' if source_inbox.campaigns.exists?
    if conversation_scope.where.not(campaign_id: nil).exists?
      blockers << 'Inbox conversations reference campaign_id. v1 aborts on campaign-linked history.'
    end
    if message_scope.where("additional_attributes ? 'campaign_id'").exists?
      blockers << 'Inbox messages carry campaign metadata in additional_attributes. v1 aborts on campaign-linked history.'
    end
    blockers << 'Referenced contacts have notes. v1 aborts instead of migrating notes.' if Note.exists?(contact_id: source_contact_ids)
    blockers.concat(sla_blockers(conversation_scope))
    blockers.concat(custom_table_blockers(conversation_scope))
    blockers.concat(contact_plan[:ambiguities].map do |ambiguity|
      "Ambiguous target contact match for source contact #{ambiguity[:source_contact_id]} (candidate target contact ids: #{ambiguity[:candidate_ids].join(', ')})"
    end)

    warnings << "#{source_inbox.inbox_members.count} inbox members will be removed from the moved inbox." if source_inbox.inbox_members.exists?
    warnings << 'Inbox assignment policy will be removed during execute.' if source_inbox.inbox_assignment_policy.present?
    warnings << 'Agent bot inbox link will be removed during execute.' if source_inbox.agent_bot_inbox.present?
    if ConversationParticipant.exists?(conversation_id: conversation_scope.select(:id))
      warnings << "#{ConversationParticipant.where(conversation_id: conversation_scope.select(:id)).count} conversation participants will be deleted."
    end
    if Mention.exists?(conversation_id: conversation_scope.select(:id))
      warnings << "#{Mention.where(conversation_id: conversation_scope.select(:id)).count} mentions will be deleted."
    end
    if CsatSurveyResponse.exists?(conversation_id: conversation_scope.select(:id))
      warnings << 'CSAT assigned-agent metadata will be cleared during execute.'
    end
    if ReportingEvent.exists?(conversation_id: conversation_scope.select(:id))
      warnings << 'Reporting event user attribution will be cleared during execute.'
    end

    user_sender_count = message_scope.where(sender_type: 'User').count
    if user_sender_count.positive?
      warnings << "#{user_sender_count} messages have sender_type='User'; sender_id is preserved (cross-account authorship for history)."
    end
    bot_sender_count = message_scope.where(sender_type: 'AgentBot').count
    if bot_sender_count.positive?
      warnings << "#{bot_sender_count} messages have sender_type='AgentBot'; sender_id preserved (may reference source-account bot)."
    end

    notifications_scope = notifications_scope_for(conversation_scope, message_scope)
    warnings << "#{notifications_scope.count} notifications tied to these conversations/messages will be deleted." if notifications_scope.exists?

    {
      blockers: blockers,
      warnings: warnings,
      counts: {
        conversations: conversation_scope.count,
        messages: message_scope.count,
        attachments: Attachment.where(message_id: message_scope.select(:id)).count,
        source_contacts: source_contacts.size,
        contact_inboxes: ContactInbox.where(inbox_id: source_inbox.id).count,
        reporting_events: ReportingEvent.where(conversation_id: conversation_scope.select(:id)).count,
        csat_survey_responses: CsatSurveyResponse.where(conversation_id: conversation_scope.select(:id)).count,
        inbox_members: source_inbox.inbox_members.count,
        conversation_participants: ConversationParticipant.where(conversation_id: conversation_scope.select(:id)).count,
        mentions: Mention.where(conversation_id: conversation_scope.select(:id)).count,
        notifications: notifications_scope.count,
        labels_to_ensure: label_titles.size,
        contacts_to_reuse: contact_plan[:reuse].size,
        contacts_to_clone: contact_plan[:clones].size
      },
      contact_plan: contact_plan,
      label_titles: label_titles
    }
  end

  def execute_migration!(summary)
    conversation_scope = Conversation.where(inbox_id: source_inbox.id)
    message_scope = Message.where(conversation_id: conversation_scope.select(:id))
    notifications_scope = notifications_scope_for(conversation_scope, message_scope)
    contact_map = summary[:contact_plan][:reuse].dup

    ActiveRecord::Base.transaction do
      ensure_target_labels!(summary[:label_titles])
      create_cloned_contacts!(summary[:contact_plan][:clones], contact_map)
      remap_contact_inboxes!(contact_map)
      remap_messages!(message_scope, contact_map)
      delete_user_scoped_artifacts!(conversation_scope, notifications_scope)
      remap_csat_survey_responses!(conversation_scope, contact_map)
      remap_reporting_events!(conversation_scope)
      remap_conversations!(conversation_scope, contact_map)
      detach_inbox_from_source_account!
      cleanup_inbox_configuration!
    end

    source_account.reset_cache_keys
    target_account.reset_cache_keys
  end

  def dump_pre_migration_snapshot!(summary)
    conversation_scope = Conversation.where(inbox_id: source_inbox.id)
    message_scope = Message.where(conversation_id: conversation_scope.select(:id))
    notifications_scope = notifications_scope_for(conversation_scope, message_scope)
    target_match_ids = summary[:contact_plan][:reuse].values.uniq

    payload = {
      metadata: snapshot_metadata,
      plan: {
        contacts_to_reuse: summary[:contact_plan][:reuse],
        contacts_to_clone_ids: summary[:contact_plan][:clones].map(&:id),
        labels_to_ensure: summary[:label_titles]
      },
      before: {
        inbox: dump_rows(Inbox.where(id: source_inbox.id)),
        channel_whatsapp: dump_rows(Channel::Whatsapp.where(id: source_inbox.channel_id)),
        conversations: dump_rows(conversation_scope),
        messages: dump_rows(message_scope),
        attachments: dump_rows(Attachment.where(message_id: message_scope.select(:id))),
        contact_inboxes: dump_rows(ContactInbox.where(inbox_id: source_inbox.id)),
        csat_survey_responses: dump_rows(CsatSurveyResponse.where(conversation_id: conversation_scope.select(:id))),
        reporting_events: dump_rows(ReportingEvent.where(conversation_id: conversation_scope.select(:id))),
        notifications: dump_rows(notifications_scope),
        conversation_participants: dump_rows(ConversationParticipant.where(conversation_id: conversation_scope.select(:id))),
        mentions: dump_rows(Mention.where(conversation_id: conversation_scope.select(:id))),
        inbox_members: dump_rows(source_inbox.inbox_members),
        inbox_assignment_policy: dump_rows(InboxAssignmentPolicy.where(inbox_id: source_inbox.id)),
        agent_bot_inbox: dump_rows(AgentBotInbox.where(inbox_id: source_inbox.id)),
        source_contacts: dump_rows(Contact.where(id: ContactInbox.where(inbox_id: source_inbox.id).select(:contact_id))),
        target_contacts_to_reuse: dump_rows(Contact.where(id: target_match_ids))
      }
    }

    path = resolve_snapshot_path
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.pretty_generate(payload))
    File.expand_path(path)
  end

  def snapshot_metadata
    {
      script: File.basename(__FILE__),
      generated_at: Time.now.utc.iso8601,
      mode: options[:mode],
      source_inbox_id: source_inbox.id,
      source_account_id: source_account.id,
      target_account_id: target_account.id,
      ruby_version: RUBY_VERSION,
      rails_env: Rails.env
    }
  end

  def dump_rows(relation)
    sql = relation.respond_to?(:to_sql) ? relation.to_sql : nil
    return [] unless sql

    ActiveRecord::Base.connection.select_all(sql).to_a
  end

  def resolve_snapshot_path
    return options[:snapshot_path] if options[:snapshot_path].present?

    timestamp = Time.now.utc.strftime('%Y%m%dT%H%M%SZ')
    Rails.root.join('tmp/migration_snapshots', "inbox_#{source_inbox.id}_#{timestamp}.json").to_s
  end

  def sla_blockers(conversation_scope)
    blockers = []
    if conversation_scope.where.not(sla_policy_id: nil).exists?
      blockers << 'Inbox conversations reference sla_policy_id. v1 aborts on SLA-linked history.'
    end

    if table_exists?('applied_slas') && ActiveRecord::Base.connection.select_value("SELECT 1 FROM applied_slas WHERE conversation_id IN (#{conversation_scope.select(:id).to_sql}) LIMIT 1")
      blockers << 'Applied SLA rows exist for these conversations. v1 aborts on SLA-linked history.'
    end

    if table_exists?('sla_events') && ActiveRecord::Base.connection.select_value("SELECT 1 FROM sla_events WHERE conversation_id IN (#{conversation_scope.select(:id).to_sql}) LIMIT 1")
      blockers << 'SLA event rows exist for these conversations. v1 aborts on SLA-linked history.'
    end

    blockers
  end

  def custom_table_blockers(conversation_scope)
    blockers = []
    inbox_id = source_inbox.id
    account_id = source_account.id
    conv_ids_sql = conversation_scope.select(:id).to_sql

    if table_exists?('calls') && ActiveRecord::Base.connection.select_value("SELECT 1 FROM calls WHERE inbox_id = #{inbox_id} LIMIT 1")
      blockers << 'Call rows exist for this inbox. v1 aborts on call-linked history.'
    end

    if table_exists?('captain_inboxes') && ActiveRecord::Base.connection.select_value("SELECT 1 FROM captain_inboxes WHERE inbox_id = #{inbox_id} LIMIT 1")
      blockers << 'Captain inbox link exists. v1 aborts on captain-assistant-linked inboxes.'
    end

    if table_exists?('inbox_capacity_limits') && ActiveRecord::Base.connection.select_value("SELECT 1 FROM inbox_capacity_limits WHERE inbox_id = #{inbox_id} LIMIT 1")
      blockers << 'Inbox capacity limits exist. v1 aborts on capacity-policy-linked inboxes.'
    end

    if table_exists?('captain_assistant_responses') && ActiveRecord::Base.connection.select_value("SELECT 1 FROM captain_assistant_responses WHERE documentable_type = 'Conversation' AND documentable_id IN (#{conv_ids_sql}) LIMIT 1")
      blockers << 'Captain assistant responses reference these conversations. v1 aborts on captain-linked history.'
    end

    if table_exists?('reporting_events_rollups') && ActiveRecord::Base.connection.select_value("SELECT 1 FROM reporting_events_rollups WHERE account_id = #{account_id} AND dimension_type = 'inbox' AND dimension_id = #{inbox_id} LIMIT 1")
      blockers << 'Reporting events rollups exist for this inbox. v1 aborts on rollup-linked analytics.'
    end

    blockers
  end

  def table_exists?(table_name)
    ActiveRecord::Base.connection.data_source_exists?(table_name)
  end

  def build_contact_plan(source_contacts)
    identifiers = source_contacts.filter_map(&:identifier).map(&:strip).reject(&:blank?).uniq
    emails = source_contacts.filter_map { |contact| normalized_email(contact.email) }.uniq
    phones = source_contacts.filter_map(&:phone_number).map(&:strip).reject(&:blank?).uniq

    target_matches = []
    target_matches.concat(target_account.contacts.where(identifier: identifiers).to_a) if identifiers.any?
    target_matches.concat(target_account.contacts.where('lower(email) IN (?)', emails).to_a) if emails.any?
    target_matches.concat(target_account.contacts.where(phone_number: phones).to_a) if phones.any?
    target_matches.uniq!(&:id)

    by_identifier = Hash.new { |hash, key| hash[key] = [] }
    by_email = Hash.new { |hash, key| hash[key] = [] }
    by_phone = Hash.new { |hash, key| hash[key] = [] }

    target_matches.each do |contact|
      by_identifier[contact.identifier] << contact.id if contact.identifier.present?
      by_email[normalized_email(contact.email)] << contact.id if contact.email.present?
      by_phone[contact.phone_number] << contact.id if contact.phone_number.present?
    end

    reuse = {}
    clones = []
    ambiguities = []

    source_contacts.each do |contact|
      candidate_ids = Set.new
      candidate_ids.merge(by_identifier[contact.identifier]) if contact.identifier.present?
      candidate_ids.merge(by_email[normalized_email(contact.email)]) if contact.email.present?
      candidate_ids.merge(by_phone[contact.phone_number]) if contact.phone_number.present?

      case candidate_ids.size
      when 0
        clones << contact
      when 1
        reuse[contact.id] = candidate_ids.first
      else
        ambiguities << { source_contact_id: contact.id, candidate_ids: candidate_ids.to_a.sort }
      end
    end

    { reuse: reuse, clones: clones, ambiguities: ambiguities }
  end

  def normalized_email(email)
    email.to_s.strip.downcase.presence
  end

  def migrated_label_titles(conversation_scope)
    conversation_scope.where.not(cached_label_list: [nil, '']).pluck(:cached_label_list)
                      .flat_map { |value| value.to_s.split(',').map(&:strip) }
                      .reject(&:blank?)
                      .uniq
                      .sort
  end

  def ensure_target_labels!(titles)
    return if titles.blank?

    existing_titles = target_account.labels.where(title: titles).pluck(:title).to_set
    missing_titles = titles.reject { |title| existing_titles.include?(title) }
    return if missing_titles.blank?

    source_labels = source_account.labels.where(title: missing_titles).index_by(&:title)

    rows = missing_titles.map do |title|
      label = source_labels[title]
      {
        title: title,
        description: label&.description,
        color: label&.color || '#1f93ff',
        show_on_sidebar: label&.show_on_sidebar,
        account_id: target_account.id,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    Label.insert_all!(rows) if rows.any?
  end

  def create_cloned_contacts!(contacts_to_clone, contact_map)
    column_names = Contact.column_names - %w[id account_id company_id]
    contacts_to_clone.each do |source_contact|
      attrs = source_contact.attributes.slice(*column_names)
      attrs['account_id'] = target_account.id
      attrs['company_id'] = nil

      result = Contact.insert_all!([attrs], returning: %w[id])
      contact_map[source_contact.id] = result.rows.first.first
    end
  end

  def remap_contact_inboxes!(contact_map)
    return if contact_map.blank?

    ContactInbox.where(inbox_id: source_inbox.id, contact_id: contact_map.keys)
                .update_all("contact_id = #{case_sql('contact_id', contact_map)}")
  end

  def remap_messages!(message_scope, contact_map)
    message_scope.where.not(sender_type: 'Contact').update_all(account_id: target_account.id, inbox_id: source_inbox.id)
    if contact_map.present?
      message_scope.where(sender_type: 'Contact')
                   .update_all("account_id = #{target_account.id}, inbox_id = #{source_inbox.id}, sender_id = #{case_sql('sender_id', contact_map)}")
    end

    Attachment.where(message_id: message_scope.select(:id)).update_all(account_id: target_account.id)
  end

  def delete_user_scoped_artifacts!(conversation_scope, notifications_scope)
    ConversationParticipant.where(conversation_id: conversation_scope.select(:id)).delete_all
    Mention.where(conversation_id: conversation_scope.select(:id)).delete_all
    notifications_scope.delete_all
  end

  def remap_csat_survey_responses!(conversation_scope, contact_map)
    scope = CsatSurveyResponse.where(conversation_id: conversation_scope.select(:id))
    if contact_map.blank?
      return scope.update_all(
        account_id: target_account.id,
        assigned_agent_id: nil,
        review_notes_updated_by_id: nil
      )
    end

    scope.update_all(
      "account_id = #{target_account.id}, contact_id = #{case_sql('contact_id', contact_map)}, " \
      'assigned_agent_id = NULL, review_notes_updated_by_id = NULL'
    )
  end

  def remap_reporting_events!(conversation_scope)
    ReportingEvent.where(conversation_id: conversation_scope.select(:id))
                  .update_all(account_id: target_account.id, inbox_id: source_inbox.id, user_id: nil)
  end

  def remap_conversations!(conversation_scope, contact_map)
    update_sql = [
      "account_id = #{target_account.id}",
      "display_id = nextval('conv_dpid_seq_#{target_account.id}')",
      'assignee_id = NULL',
      'assignee_last_seen_at = NULL',
      'team_id = NULL',
      'assignee_agent_bot_id = NULL',
      'campaign_id = NULL',
      'sla_policy_id = NULL'
    ]
    update_sql << "contact_id = #{case_sql('contact_id', contact_map)}" if contact_map.present?

    conversation_scope.update_all(update_sql.join(', '))
  end

  def detach_inbox_from_source_account!
    source_inbox.update_columns(account_id: target_account.id)
    source_inbox.channel.update_columns(account_id: target_account.id)
  end

  def cleanup_inbox_configuration!
    source_inbox.inbox_assignment_policy&.delete
    source_inbox.agent_bot_inbox&.delete
    source_inbox.inbox_members.delete_all
    AutoAssignment::InboxRoundRobinService.new(inbox: source_inbox).clear_queue
  end

  def notifications_scope_for(conversation_scope, message_scope)
    Notification.where(primary_actor_type: 'Conversation', primary_actor_id: conversation_scope.select(:id))
                .or(Notification.where(secondary_actor_type: 'Message', secondary_actor_id: message_scope.select(:id)))
  end

  def case_sql(column_name, mapping)
    clauses = mapping.map { |from_id, to_id| "WHEN #{column_name} = #{Integer(from_id)} THEN #{Integer(to_id)}" }.join(' ')
    "CASE #{clauses} ELSE #{column_name} END"
  end

  def print_header
    puts '=' * 80
    puts 'WhatsApp inbox account migration (v1)'
    puts "Mode: #{options[:mode]}"
    puts "Source inbox: #{source_inbox.id}"
    puts "Source account: #{source_account.id}"
    puts "Target account: #{target_account.id}"
    puts '=' * 80
  end

  def print_summary(summary)
    puts ''
    puts 'Counts'
    summary[:counts].each do |key, value|
      puts format('  %<label>-28s %<value>s', label: "#{key}:", value: value)
    end

    puts ''
    puts 'Warnings'
    if summary[:warnings].any?
      summary[:warnings].each { |warning| puts "  - #{warning}" }
    else
      puts '  - none'
    end

    puts ''
    puts 'Blockers'
    if summary[:blockers].any?
      summary[:blockers].each { |blocker| puts "  - #{blocker}" }
    else
      puts '  - none'
    end

    puts ''
    puts(execute? ? 'Execute mode will continue because no blockers were found.' : 'Dry run finished. Re-run with --mode=execute after review.')
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
# rubocop:enable Rails/SkipsModelValidations, Layout/LineLength

WhatsappInboxAccountMigration.run(ARGV)
