require 'json'
require 'fileutils'
require 'csv'

namespace :captain do
  namespace :assistant_migration do
    desc 'Generate structured migration drafts. Usage: rake captain:assistant_migration:generate IDS=1,2,3 LIMIT=50 OUTPUT=tmp/captain_migration.jsonl'
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

    desc 'Apply reviewed migration drafts. Usage: rake captain:assistant_migration:apply INPUT=tmp/reviewed.jsonl DRY_RUN=true APPLY_SCENARIOS=false'
    task apply: :environment do
      input_path = ENV.fetch('INPUT')
      dry_run = CaptainAssistantMigrationTask.truthy?('DRY_RUN', default: true)
      apply_scenarios = CaptainAssistantMigrationTask.truthy?('APPLY_SCENARIOS', default: false)

      results = CaptainAssistantMigrationTask.apply_drafts(
        input_path: input_path,
        dry_run: dry_run,
        apply_scenarios: apply_scenarios
      )

      results.each { |result| puts(JSON.generate(result)) }
      puts "Processed #{results.size} migration drafts from #{input_path}"
      puts 'Dry run only. Re-run with DRY_RUN=false to write changes.' if dry_run
    end
  end
end

class CaptainAssistantMigrationTask
  CsvAccount = Struct.new(:id, :name, keyword_init: true) do
    def captain_models
      {}
    end

    def conversations
      CsvRelation.new
    end
  end

  CsvAssociation = Struct.new(:size, keyword_init: true)

  class CsvRelation
    def find_by(*)
      nil
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
      return scope.where(id: ids) if ids.any?

      scope = scope.where("NULLIF(config->>'instructions', '') IS NOT NULL")
                   .order(:id)

      limit = ENV.fetch('LIMIT', 50).to_i
      limit.positive? ? scope.limit(limit) : scope
    end

    def each_assistant(assistants, &block)
      return assistants.find_each(&block) if assistants.respond_to?(:find_each)

      assistants.each(&block)
    end

    def assistant_count(assistants)
      assistants.respond_to?(:size) ? assistants.size : assistants.count
    end

    def apply_drafts(input_path:, dry_run:, apply_scenarios:)
      File.readlines(input_path, chomp: true).filter_map.with_index(1) do |line, line_number|
        next if line.blank?

        apply_draft(JSON.parse(line), line_number: line_number, dry_run: dry_run, apply_scenarios: apply_scenarios)
      rescue JSON::ParserError => e
        { line_number: line_number, error: "Invalid JSON: #{e.message}" }
      end
    end

    def apply_draft(payload, line_number:, dry_run:, apply_scenarios:)
      return { line_number: line_number, skipped: true, reason: payload['error'] } if payload['error'].present?

      assistant_id = payload.dig('assistant', 'id') || payload['assistant_id']
      assistant = Captain::Assistant.find(assistant_id)
      draft = payload['draft'] || payload

      Captain::AssistantMigration::DraftApplier.new(
        assistant: assistant,
        draft: draft,
        dry_run: dry_run,
        apply_scenarios: apply_scenarios
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

    def csv_assistants
      rows = CSV.read(ENV.fetch('CSV_INPUT'), headers: true)
      ids = ENV.fetch('IDS', '').split(',').filter_map { |id| id.strip.presence }
      status = ENV.fetch('STATUS', '').presence

      assistants = rows.filter_map do |row|
        next if ids.any? && !ids.include?(row['id'].to_s)
        next if status.present? && row['status'].to_s != status

        assistant = csv_assistant(row)
        next if assistant.config['instructions'].blank?

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
        captain_inboxes: CsvAssociation.new(size: normalize_integer(row['inbox_count'])),
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
