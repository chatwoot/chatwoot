# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
namespace :reporting_events_rollup do
  desc 'Compare rollup data vs raw data for summary reports'
  task compare: :environment do
    # 1. WELCOME & PROMPT FOR ACCOUNT ID
    puts ''
    puts '=' * 70
    puts 'Reporting Events Rollup Comparison'
    puts '=' * 70
    puts ''

    print 'Enter Account ID: '
    account_id = $stdin.gets.chomp

    if account_id.blank?
      puts 'Error: Account ID is required'
      exit(1)
    end

    # 2. LOAD & VALIDATE ACCOUNT
    account = Account.find_by(id: account_id)
    unless account
      puts "Error: Account with ID #{account_id} not found"
      exit(1)
    end

    if account.reporting_timezone.blank?
      puts 'Error: Account must have reporting_timezone set'
      puts "Run: Account.find(#{account_id}).update!(reporting_timezone: 'YOUR_TIMEZONE')"
      exit(1)
    end

    unless account.feature_enabled?('reporting_events_rollup')
      puts 'Error: reporting_events_rollup feature flag must be enabled'
      puts "Run: Account.find(#{account_id}).enable_features!('reporting_events_rollup')"
      exit(1)
    end

    puts "✓ Found account: #{account.name}"
    puts "✓ Timezone: #{account.reporting_timezone}"
    puts ''

    # 3. GENERATE DAILY DATE RANGES FOR PAST 6 MONTHS
    tz = ActiveSupport::TimeZone[account.reporting_timezone]
    end_date = Time.current.in_time_zone(tz).to_date
    start_date = end_date - 6.months

    # Generate daily ranges
    days = []
    current_date = start_date
    while current_date <= end_date
      days << { start: current_date, end: current_date }
      current_date += 1.day
    end

    total_days = days.size
    puts "Generated #{total_days} daily periods from #{days.first[:start]} to #{days.last[:end]}"
    puts ''

    # 4. DISCOVER ENTITIES TO COMPARE
    agents = account.account_users.pluck(:user_id)
    inboxes = account.inboxes.pluck(:id)
    teams = account.teams.pluck(:id)

    puts 'Entities to compare:'
    puts "  - #{agents.size} agents"
    puts "  - #{inboxes.size} inboxes"
    puts "  - #{teams.size} teams"
    puts ''

    print 'Proceed with comparison? (y/N): '
    confirm = $stdin.gets.chomp.downcase

    unless confirm == 'y' || confirm == 'yes'
      puts 'Comparison cancelled'
      exit(0)
    end

    puts ''
    puts '=' * 70
    puts 'Starting Comparison'
    puts '=' * 70
    puts ''

    # 5. COMPARISON STATS
    total_comparisons = 0
    mismatches = []
    start_time = Time.current

    # 6. COMPARE EACH DIMENSION TYPE
    dimension_types = [
      { name: 'agent', builder: V2::Reports::AgentSummaryBuilder, entities: agents },
      { name: 'inbox', builder: V2::Reports::InboxSummaryBuilder, entities: inboxes },
      { name: 'team', builder: V2::Reports::TeamSummaryBuilder, entities: teams }
    ]

    dimension_types.each do |dimension|
      puts "Comparing #{dimension[:name]} summaries..."

      days.each_with_index do |day, day_index|
        # Build base params for this day
        base_params = {
          since: day[:start].to_s,
          until: day[:end].to_s,
          type: dimension[:name],
          timezone_offset: tz.utc_offset / 3600.0,
          business_hours: false
        }

        # Get raw data (explicitly disable rollup)
        raw_params = base_params.merge(use_rollup: false)
        raw_results = dimension[:builder].new(account: account, params: raw_params).build

        # Get rollup data (explicitly enable rollup)
        rollup_params = base_params.merge(use_rollup: true)
        rollup_results = dimension[:builder].new(account: account, params: rollup_params).build

        # Compare results
        dimension[:entities].each do |entity_id|
          raw_entity = raw_results.find { |r| r[:id] == entity_id }
          rollup_entity = rollup_results.find { |r| r[:id] == entity_id }

          # Skip if both are nil (entity had no activity this day)
          next if raw_entity.nil? && rollup_entity.nil?

          # Handle case where one is nil but the other isn't
          if raw_entity.nil? || rollup_entity.nil?
            mismatches << {
              dimension: dimension[:name],
              entity_id: entity_id,
              date: day[:start].to_s,
              issue: raw_entity.nil? ? 'Raw data missing' : 'Rollup data missing',
              raw: raw_entity,
              rollup: rollup_entity
            }
            next
          end

          # Compare metrics
          comparison = compare_metrics(raw_entity, rollup_entity)
          total_comparisons += 1

          next if comparison[:match]

          mismatches << {
            dimension: dimension[:name],
            entity_id: entity_id,
            date: day[:start].to_s,
            differences: comparison[:differences],
            raw: raw_entity,
            rollup: rollup_entity
          }
        end

        # Progress update
        progress = ((day_index + 1).to_f / total_days * 100).round(1)
        print "\r  Day #{day_index + 1}/#{total_days} (#{day[:start]}) | #{progress}%    "
        $stdout.flush
      end

      puts "\n✓ Completed #{dimension[:name]} comparisons\n\n"
    end

    # 7. SUMMARY REPORT
    elapsed_time = Time.current - start_time

    puts '=' * 70
    puts '✅ COMPARISON COMPLETE'
    puts '=' * 70
    puts "Total Comparisons: #{total_comparisons}"
    puts "Mismatches Found:  #{mismatches.size}"
    puts "Match Rate:        #{total_comparisons.zero? ? 'N/A' : ((1 - (mismatches.size.to_f / total_comparisons)) * 100).round(2)}%"
    puts "Elapsed Time:      #{elapsed_time.round(2)} seconds"
    puts '=' * 70

    # 8. DETAILED MISMATCH REPORT
    puts ''
    if mismatches.any?
      puts '=' * 70
      puts '❌ MISMATCHES DETECTED'
      puts '=' * 70
      puts ''

      mismatches.each_with_index do |mismatch, index|
        puts "#{index + 1}. #{mismatch[:dimension].upcase} ID: #{mismatch[:entity_id]} | Date: #{mismatch[:date]}"

        if mismatch[:issue]
          puts "   Issue: #{mismatch[:issue]}"
        elsif mismatch[:differences]
          mismatch[:differences].each do |diff|
            puts "   #{diff[:metric]}:"
            puts "     Raw:    #{diff[:raw].nil? ? 'nil' : diff[:raw].round(2)}"
            puts "     Rollup: #{diff[:rollup].nil? ? 'nil' : diff[:rollup].round(2)}"
            puts "     Delta:  #{diff[:delta]}"
          end
        end

        puts ''
      end

      puts '=' * 70
      puts 'RECOMMENDATION:'
      puts 'Investigate mismatches above. Possible causes:'
      puts '  - Rollup data not backfilled for these date ranges'
      puts '  - Timezone mismatch between rollup and raw data'
      puts '  - Data corruption in rollup table'
      puts '  - Bug in rollup aggregation logic'
      puts '=' * 70
    else
      puts '🎉 All comparisons passed! Rollup data matches raw data perfectly.'
      puts ''
    end
  end

  # Helper: Compare two metric hashes
  def compare_metrics(raw, rollup)
    metrics_to_compare = %i[
      conversations_count
      resolved_conversations_count
      avg_resolution_time
      avg_first_response_time
      avg_reply_time
    ]

    differences = []

    metrics_to_compare.each do |metric|
      raw_value = raw[metric]
      rollup_value = rollup[metric]

      # Handle nil values
      next if raw_value.nil? && rollup_value.nil?

      # For counts, exact match required
      if metric.to_s.include?('count')
        if raw_value != rollup_value
          differences << {
            metric: metric,
            raw: raw_value,
            rollup: rollup_value,
            delta: ((rollup_value || 0) - (raw_value || 0)).to_s
          }
        end
      else
        # For averages, allow small floating point difference (0.01 seconds)
        raw_f = raw_value.to_f
        rollup_f = rollup_value.to_f
        delta = (rollup_f - raw_f).abs

        if delta > 0.01 # More than 0.01 seconds difference
          differences << {
            metric: metric,
            raw: raw_value,
            rollup: rollup_value,
            delta: "#{(rollup_f - raw_f).round(2)} seconds"
          }
        end
      end
    end

    {
      match: differences.empty?,
      differences: differences
    }
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
