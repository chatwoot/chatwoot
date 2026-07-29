require 'json'
require 'fileutils'
require 'csv'

# rubocop:disable Metrics/BlockLength
namespace :captain do
  namespace :assistant_migration do
    desc 'Generate structured migration drafts. Usage: rake captain:assistant_migration:generate IDS=1,2,3 LIMIT=50 ' \
         'OUTPUT=tmp/captain_migration.jsonl'
    task generate: :environment do
      assistants = CaptainAssistantMigrationTask.assistants
      output_path = ENV.fetch('OUTPUT', Rails.root.join('tmp/captain_assistant_migration_drafts.jsonl').to_s)

      FileUtils.mkdir_p(File.dirname(output_path))
      processed = 0

      File.open(output_path, 'w') do |file|
        CaptainAssistantMigrationTask.each_assistant(assistants) do |assistant|
          result = Captain::AssistantMigration::InstructionClassifier.new(assistant: assistant).perform
          file.puts(JSON.generate(result))
          processed += 1
          puts "Generated migration draft for assistant #{assistant.id} (#{processed}/#{CaptainAssistantMigrationTask.assistant_count(assistants)})"
        end
      end

      puts "Wrote #{processed} migration drafts to #{output_path}"
    end

    desc 'Apply reviewed migration drafts. Usage: rake captain:assistant_migration:apply INPUT=tmp/reviewed.jsonl DRY_RUN=true'
    task apply: :environment do
      input_path = ENV.fetch('INPUT')
      dry_run = CaptainAssistantMigrationTask.truthy?('DRY_RUN', default: true)

      results = CaptainAssistantMigrationTask.apply_drafts(
        input_path: input_path,
        dry_run: dry_run
      )

      results.each { |result| puts(JSON.generate(result)) }
      puts "Processed #{results.size} migration drafts from #{input_path}"
      puts 'Dry run only. Re-run with DRY_RUN=false to write changes.' if dry_run
    end

    desc 'Restore conversation message config from migration backup. Usage: rake captain:assistant_migration:restore_messages IDS=1,2 DRY_RUN=true'
    task restore_messages: :environment do
      dry_run = CaptainAssistantMigrationTask.truthy?('DRY_RUN', default: true)
      results = CaptainAssistantMigrationTask.restore_conversation_messages(dry_run: dry_run)

      results.each { |result| puts(JSON.generate(result)) }
      puts "Processed #{results.size} assistant message restores"
      puts 'Dry run only. Re-run with DRY_RUN=false to restore conversation messages.' if dry_run
    end
  end
end
# rubocop:enable Metrics/BlockLength

# rubocop:disable Style/OneClassPerFile
class CaptainAssistantMigrationTask
  CsvAccount = Struct.new(:id, :name, keyword_init: true) do
    def captain_models
      {}
    end

    def conversations
      CsvRelation.new
    end
  end

  CsvAssociation = Struct.new(:inbox_count, keyword_init: true) do
    def size
      inbox_count
    end
  end

  class CsvRelation
    def find_by(*)
      nil
    end

    def exists?
      false
    end
  end

  CsvAssistant = Struct.new(
    :id,
    :name,
    :account_id,
    :account,
    :description,
    :config,
    :response_guidelines,
    :guardrails,
    :captain_inboxes,
    :scenarios,
    keyword_init: true
  )

  class << self
    def assistants
      return csv_assistants if ENV['CSV_INPUT'].present?

      scope = Captain::Assistant.includes(:account, :captain_inboxes, :scenarios)

      ids = ENV.fetch('IDS', '').split(',').filter_map { |id| id.strip.presence }
      scope = scope.where(id: ids) if ids.any?

      scope = migration_eligible_scope(scope).order(:id)

      limit = ENV.fetch('LIMIT', 50).to_i
      limit.positive? ? scope.limit(limit) : scope
    end

    def each_assistant(assistants, &)
      return assistants.find_each(&) if assistants.respond_to?(:find_each)

      assistants.each(&)
    end

    def assistant_count(assistants)
      assistants.respond_to?(:size) ? assistants.size : assistants.count
    end

    def restore_conversation_messages(dry_run:)
      ENV.fetch('IDS').split(',').filter_map { |id| id.strip.presence }.map do |assistant_id|
        assistant = Captain::Assistant.find(assistant_id)
        restore_conversation_messages_for(assistant, dry_run: dry_run)
      rescue ActiveRecord::RecordNotFound
        { assistant_id: assistant_id, error: 'Assistant not found' }
      end
    end

    def apply_drafts(input_path:, dry_run:)
      File.readlines(input_path, chomp: true).filter_map.with_index(1) do |line, line_number|
        next if line.blank?

        apply_draft(JSON.parse(line), line_number: line_number, dry_run: dry_run)
      rescue JSON::ParserError => e
        { line_number: line_number, error: "Invalid JSON: #{e.message}" }
      end
    end

    def apply_draft(payload, line_number:, dry_run:)
      return { line_number: line_number, skipped: true, reason: payload['error'] } if payload['error'].present?

      assistant_id = payload.dig('assistant', 'id') || payload['assistant_id']
      assistant = Captain::Assistant.find(assistant_id)
      return skipped_result(line_number, assistant_id, 'Assistant is not a V1 migration candidate') unless migration_candidate?(assistant)

      draft = payload['draft'] || payload

      Captain::AssistantMigration::DraftApplier.new(
        assistant: assistant,
        draft: draft,
        dry_run: dry_run
      ).perform.merge(line_number: line_number)
    rescue ActiveRecord::RecordNotFound
      { line_number: line_number, assistant_id: assistant_id, error: 'Assistant not found' }
    end

    def truthy?(key, default:)
      value = ENV.fetch(key, nil)
      return default if value.nil?

      value.to_s.downcase.in?(%w[1 true yes y])
    end

    private

    def restore_conversation_messages_for(assistant, dry_run:)
      original_config = assistant.config.dig(
        Captain::AssistantMigration::DraftApplier::CONFIG_KEY,
        Captain::AssistantMigration::DraftApplier::ORIGINAL_VALUES_KEY,
        'config'
      )
      return skipped_result(nil, assistant.id, 'No stored migration original config found') if original_config.nil?

      config, changes = restored_message_config(assistant.config.deep_dup, original_config)
      assistant.update!(config: config) if !dry_run && changes.present?

      { assistant_id: assistant.id, dry_run: dry_run, changes: changes }
    end

    def restored_message_config(config, original_config)
      changes = {}
      %w[welcome_message handoff_message resolution_message].each do |key|
        original_present = original_config.key?(key)
        next if config[key] == original_config[key] && config.key?(key) == original_present

        changes[key] = { from: config[key], to: original_config[key] }
        original_present ? config[key] = original_config[key] : config.delete(key)
      end
      [config, changes]
    end

    def skipped_result(line_number, assistant_id, reason)
      {
        line_number: line_number,
        assistant_id: assistant_id,
        skipped: true,
        reason: reason
      }
    end

    def migration_eligible_scope(scope)
      scope.left_outer_joins(:scenarios)
           .joins(:captain_inboxes)
           .where("NULLIF(captain_assistants.config->>'instructions', '') IS NOT NULL")
           .where("captain_assistants.response_guidelines IS NULL OR captain_assistants.response_guidelines = '[]'::jsonb")
           .where("captain_assistants.guardrails IS NULL OR captain_assistants.guardrails = '[]'::jsonb")
           .where(captain_scenarios: { id: nil })
           .distinct
    end

    def migration_candidate?(assistant)
      assistant.config['instructions'].present? &&
        assistant.captain_inboxes.size.positive? &&
        Array(assistant.response_guidelines).blank? &&
        Array(assistant.guardrails).blank? &&
        !scenarios_exist?(assistant)
    end

    def scenarios_exist?(assistant)
      scenarios = assistant.scenarios
      return scenarios.exists? if scenarios.respond_to?(:exists?)

      scenarios.present?
    end

    def csv_assistants # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      rows = CSV.read(ENV.fetch('CSV_INPUT'), headers: true)
      ids = ENV.fetch('IDS', '').split(',').filter_map { |id| id.strip.presence }
      status = ENV.fetch('STATUS', '').presence

      assistants = rows.filter_map do |row|
        next if ids.any? && ids.exclude?(row['id'].to_s)
        next if status.present? && row['status'].to_s != status

        assistant = csv_assistant(row)
        next unless migration_candidate?(assistant)

        assistant
      end

      limit = ENV.fetch('LIMIT', 50).to_i
      limit.positive? ? assistants.first(limit) : assistants
    end

    def csv_assistant(row)
      config = parse_json(row['config'], fallback: {})
      CsvAssistant.new(
        id: normalize_integer(row['id']),
        name: row['name'].to_s,
        account_id: normalize_integer(row['account_id']),
        account: CsvAccount.new(id: normalize_integer(row['account_id']), name: row['account_name'].to_s),
        description: row['description'].to_s,
        config: config,
        response_guidelines: parse_json(row['response_guidelines'], fallback: []),
        guardrails: parse_json(row['guardrails'], fallback: []),
        captain_inboxes: CsvAssociation.new(inbox_count: normalize_integer(row['inbox_count'])),
        scenarios: []
      )
    end

    def parse_json(value, fallback:)
      return fallback if value.blank?

      JSON.parse(value)
    rescue JSON::ParserError
      fallback
    end

    def normalize_integer(value)
      value.to_s.delete(',').to_i
    end
  end
end
# rubocop:enable Style/OneClassPerFile
