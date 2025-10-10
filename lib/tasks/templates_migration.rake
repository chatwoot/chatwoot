# frozen_string_literal: true

# Unified Template System Migration Tasks
# Purpose: Migrate existing templates from various channels to the unified template system
#
# Usage:
#   rake templates:migrate:all              - Migrate all templates from all sources
#   rake templates:migrate:whatsapp         - Migrate WhatsApp templates only
#   rake templates:migrate:twilio           - Migrate Twilio SMS templates only
#   rake templates:migrate:apple_messages   - Migrate Apple Messages templates only
#   rake templates:migrate:canned_responses - Migrate canned responses only
#   rake templates:rollback:all             - Rollback all migrations
#   rake templates:validate                 - Validate migration results

namespace :templates do
  namespace :migrate do
    desc 'Migrate all templates from all sources to unified template system'
    task all: :environment do
      puts '=' * 80
      puts 'Starting Unified Template System Migration'
      puts '=' * 80
      puts ''

      # Track overall stats
      total_stats = {
        whatsapp: { total: 0, migrated: 0, failed: 0 },
        twilio: { total: 0, migrated: 0, failed: 0 },
        apple_messages: { total: 0, migrated: 0, failed: 0 },
        canned_responses: { total: 0, migrated: 0, failed: 0 }
      }

      # Run all migrations in sequence
      ['whatsapp', 'twilio', 'apple_messages', 'canned_responses'].each do |source|
        puts "\n" + '-' * 80
        puts "Migrating #{source.titleize} Templates"
        puts '-' * 80

        begin
          stats = run_migration(source)
          total_stats[source.to_sym] = stats
        rescue StandardError => e
          puts "❌ Error migrating #{source}: #{e.message}"
          puts e.backtrace.first(5).join("\n")
          total_stats[source.to_sym][:failed] += 1
        end
      end

      # Print summary
      print_migration_summary(total_stats)
    end

    desc 'Migrate WhatsApp templates from message_templates JSONB field'
    task whatsapp: :environment do
      puts 'Migrating WhatsApp Templates...'
      stats = Templates::Migration::WhatsappMigrationService.new.migrate
      print_stats('WhatsApp', stats)
    end

    desc 'Migrate Twilio SMS templates from content_templates JSONB field'
    task twilio: :environment do
      puts 'Migrating Twilio SMS Templates...'
      stats = Templates::Migration::TwilioMigrationService.new.migrate
      print_stats('Twilio SMS', stats)
    end

    desc 'Migrate Apple Messages rich content templates'
    task apple_messages: :environment do
      puts 'Migrating Apple Messages Templates...'
      stats = Templates::Migration::AppleMessagesMigrationService.new.migrate
      print_stats('Apple Messages', stats)
    end

    desc 'Migrate canned_responses to unified templates'
    task canned_responses: :environment do
      puts 'Migrating Canned Responses...'
      stats = Templates::Migration::CannedResponseMigrationService.new.migrate
      print_stats('Canned Responses', stats)
    end
  end

  namespace :rollback do
    desc 'Rollback all template migrations'
    task all: :environment do
      puts '=' * 80
      puts 'Rolling Back Unified Template System Migration'
      puts '=' * 80
      puts ''
      puts '⚠️  WARNING: This will delete all migrated templates!'
      puts '⚠️  Original data in JSONB fields will NOT be restored automatically.'
      puts ''
      print 'Are you sure you want to continue? (yes/no): '

      confirmation = STDIN.gets.chomp
      unless confirmation.downcase == 'yes'
        puts 'Rollback cancelled.'
        exit
      end

      total_deleted = 0

      # Delete templates with migration metadata
      migration_sources = ['whatsapp_migration', 'twilio_migration', 'apple_messages_migration', 'canned_response_migration']

      migration_sources.each do |source|
        count = MessageTemplate.where("metadata->>'migration_source' = ?", source).count
        MessageTemplate.where("metadata->>'migration_source' = ?", source).destroy_all
        total_deleted += count
        puts "✓ Deleted #{count} templates from #{source}"
      end

      puts ''
      puts '=' * 80
      puts "Rollback Complete: #{total_deleted} templates deleted"
      puts '=' * 80
    end

    desc 'Rollback WhatsApp template migration'
    task whatsapp: :environment do
      count = MessageTemplate.where("metadata->>'migration_source' = ?", 'whatsapp_migration').count
      MessageTemplate.where("metadata->>'migration_source' = ?", 'whatsapp_migration').destroy_all
      puts "✓ Rolled back #{count} WhatsApp templates"
    end

    desc 'Rollback Twilio template migration'
    task twilio: :environment do
      count = MessageTemplate.where("metadata->>'migration_source' = ?", 'twilio_migration').count
      MessageTemplate.where("metadata->>'migration_source' = ?", 'twilio_migration').destroy_all
      puts "✓ Rolled back #{count} Twilio templates"
    end

    desc 'Rollback Apple Messages template migration'
    task apple_messages: :environment do
      count = MessageTemplate.where("metadata->>'migration_source' = ?", 'apple_messages_migration').count
      MessageTemplate.where("metadata->>'migration_source' = ?", 'apple_messages_migration').destroy_all
      puts "✓ Rolled back #{count} Apple Messages templates"
    end

    desc 'Rollback canned response migration'
    task canned_responses: :environment do
      count = MessageTemplate.where("metadata->>'migration_source' = ?", 'canned_response_migration').count
      MessageTemplate.where("metadata->>'migration_source' = ?", 'canned_response_migration').destroy_all
      puts "✓ Rolled back #{count} Canned Response templates"
    end
  end

  desc 'Validate template migration results'
  task validate: :environment do
    puts '=' * 80
    puts 'Validating Template Migration'
    puts '=' * 80
    puts ''

    validator = Templates::Migration::ValidationService.new
    results = validator.validate_all

    results.each do |source, result|
      puts "\n#{source.to_s.titleize}:"
      puts "  Original Count: #{result[:original_count]}"
      puts "  Migrated Count: #{result[:migrated_count]}"
      puts "  Status: #{result[:status]}"

      if result[:errors].any?
        puts "  ❌ Errors:"
        result[:errors].each { |error| puts "    - #{error}" }
      else
        puts "  ✓ All templates migrated successfully"
      end
    end

    puts ''
    puts '=' * 80
    overall_status = results.values.all? { |r| r[:status] == 'valid' } ? '✓ VALID' : '❌ INVALID'
    puts "Overall Status: #{overall_status}"
    puts '=' * 80
  end

  desc 'Show migration statistics'
  task stats: :environment do
    puts '=' * 80
    puts 'Template Migration Statistics'
    puts '=' * 80
    puts ''

    # Count by migration source
    migration_sources = MessageTemplate.where("metadata->>'migration_source' IS NOT NULL")
                                      .group("metadata->>'migration_source'")
                                      .count

    puts 'Templates by Migration Source:'
    migration_sources.each do |source, count|
      puts "  #{source.gsub('_migration', '').titleize}: #{count}"
    end

    # Count by channel
    puts ''
    puts 'Templates by Channel:'
    channel_counts = MessageTemplate.joins(:channel_mappings)
                                    .group('template_channel_mappings.channel_type')
                                    .count

    channel_counts.each do |channel, count|
      puts "  #{channel}: #{count}"
    end

    # Total counts
    puts ''
    puts 'Overall Statistics:'
    puts "  Total Templates: #{MessageTemplate.count}"
    puts "  Total Content Blocks: #{TemplateContentBlock.count}"
    puts "  Total Channel Mappings: #{TemplateChannelMapping.count}"
    puts "  Average Blocks per Template: #{(TemplateContentBlock.count.to_f / MessageTemplate.count).round(2)}"

    puts ''
    puts '=' * 80
  end

  # Helper methods
  private

  def run_migration(source)
    case source
    when 'whatsapp'
      Templates::Migration::WhatsappMigrationService.new.migrate
    when 'twilio'
      Templates::Migration::TwilioMigrationService.new.migrate
    when 'apple_messages'
      Templates::Migration::AppleMessagesMigrationService.new.migrate
    when 'canned_responses'
      Templates::Migration::CannedResponseMigrationService.new.migrate
    else
      { total: 0, migrated: 0, failed: 0 }
    end
  end

  def print_stats(source, stats)
    puts ''
    puts "#{source} Migration Results:"
    puts "  Total Found: #{stats[:total]}"
    puts "  Successfully Migrated: #{stats[:migrated]}"
    puts "  Failed: #{stats[:failed]}"
    puts "  Success Rate: #{((stats[:migrated].to_f / stats[:total]) * 100).round(2)}%" if stats[:total] > 0
    puts ''
  end

  def print_migration_summary(total_stats)
    puts ''
    puts '=' * 80
    puts 'Migration Summary'
    puts '=' * 80
    puts ''

    grand_total = 0
    grand_migrated = 0
    grand_failed = 0

    total_stats.each do |source, stats|
      puts "#{source.to_s.titleize}:"
      puts "  Total: #{stats[:total]}"
      puts "  Migrated: #{stats[:migrated]}"
      puts "  Failed: #{stats[:failed]}"
      puts ''

      grand_total += stats[:total]
      grand_migrated += stats[:migrated]
      grand_failed += stats[:failed]
    end

    puts '-' * 80
    puts 'Overall Totals:'
    puts "  Total Templates Found: #{grand_total}"
    puts "  Successfully Migrated: #{grand_migrated}"
    puts "  Failed: #{grand_failed}"
    puts "  Overall Success Rate: #{((grand_migrated.to_f / grand_total) * 100).round(2)}%" if grand_total > 0
    puts ''
    puts '=' * 80

    if grand_failed > 0
      puts '⚠️  Some templates failed to migrate. Run `rake templates:validate` for details.'
    else
      puts '✓ All templates migrated successfully!'
    end
    puts '=' * 80
  end
end
