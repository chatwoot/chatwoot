# frozen_string_literal: true

namespace :reporting_events_rollup do
  desc 'Backfill rollup table from historical reporting events'
  task backfill: :environment do
    # 1. WELCOME & PROMPT FOR ACCOUNT ID
    puts ''
    puts '=' * 70
    puts 'Reporting Events Rollup Backfill'
    puts '=' * 70
    puts ''

    print 'Enter Account ID: '
    account_id = STDIN.gets.chomp

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

    puts "✓ Found account: #{account.name}"
    puts ''

    # 3. PROMPT FOR TIMEZONE
    print 'Enter Timezone (e.g., America/New_York, UTC): '
    timezone = STDIN.gets.chomp

    if timezone.blank?
      puts 'Error: Timezone is required'
      exit(1)
    end

    # 4. TIMEZONE VALIDATION
    unless ActiveSupport::TimeZone[timezone]
      puts "Error: Invalid timezone '#{timezone}'"
      puts ''
      puts 'Must be a valid IANA timezone. Examples:'
      puts '  America/New_York'
      puts '  Asia/Kolkata'
      puts '  Europe/London'
      puts '  UTC'
      puts ''
      puts 'See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones'
      exit(1)
    end

    # 5. DISCOVER DATE RANGE
    first_event = account.reporting_events.order(:created_at).first
    last_event = account.reporting_events.order(:created_at).last

    if first_event.nil?
      puts ''
      puts "No reporting events found for account #{account_id}"
      puts 'Nothing to backfill.'
      exit(0)
    end

    # Convert to account timezone dates
    tz = ActiveSupport::TimeZone[timezone]
    discovered_start_date = first_event.created_at.in_time_zone(tz).to_date
    discovered_end_date = last_event.created_at.in_time_zone(tz).to_date
    discovered_total_days = (discovered_end_date - discovered_start_date).to_i + 1

    puts "✓ Discovered date range: #{discovered_start_date} to #{discovered_end_date} (#{discovered_total_days} days)"
    puts ''

    # 6. PROMPT FOR DATE RANGE OVERRIDE
    print 'Override date range? (y/N): '
    override_range = STDIN.gets.chomp.downcase

    if override_range == 'y' || override_range == 'yes'
      print 'Enter start date (YYYY-MM-DD): '
      start_date_input = STDIN.gets.chomp
      start_date = start_date_input.present? ? start_date_input.to_date : discovered_start_date

      print 'Enter end date (YYYY-MM-DD): '
      end_date_input = STDIN.gets.chomp
      end_date = end_date_input.present? ? end_date_input.to_date : discovered_end_date
    else
      start_date = discovered_start_date
      end_date = discovered_end_date
    end

    total_days = (end_date - start_date).to_i + 1
    puts ''

    # 7. PROMPT FOR DRY RUN
    print 'Dry run? (y/N): '
    dry_run_input = STDIN.gets.chomp.downcase
    dry_run = (dry_run_input == 'y' || dry_run_input == 'yes')
    puts ''

    # 8. SHOW BACKFILL PLAN
    puts '=' * 70
    puts 'Backfill Plan Summary'
    puts '=' * 70
    puts "Account:     #{account.name} (ID: #{account_id})"
    puts "Timezone:    #{timezone}"
    puts "Date Range:  #{start_date} to #{end_date} (#{total_days} days)"
    puts "First Event: #{first_event.created_at.in_time_zone(tz).strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts "Last Event:  #{last_event.created_at.in_time_zone(tz).strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts "Dry Run:     #{dry_run ? 'YES (no data will be written)' : 'NO'}"
    puts '=' * 70
    puts ''

    if dry_run
      puts "DRY RUN MODE: Would process #{total_days} days"
      puts "Would set reporting_timezone to '#{timezone}'"
      puts 'Run without dry run to execute backfill'
      exit(0)
    end

    # 9. CONFIRMATION PROMPT
    if total_days > 730 # 2 years
      puts "⚠️  WARNING: Large backfill detected (#{total_days} days / #{(total_days / 365.0).round(1)} years)"
      puts ''
    end

    print 'Proceed with backfill? (y/N): '
    confirm = STDIN.gets.chomp.downcase

    unless confirm == 'y' || confirm == 'yes'
      puts 'Backfill cancelled'
      exit(0)
    end

    puts ''

    # 10. SAVE TIMEZONE TO ACCOUNT
    account.update!(reporting_timezone: timezone)
    puts "✓ Set reporting_timezone to '#{timezone}' for account '#{account.name}'"
    puts ''

    # 11. PROCESS EACH DATE
    puts 'Processing dates...'
    puts ''

    start_time = Time.current
    days_processed = 0

    begin
      (start_date..end_date).each do |date|
        # Process this date
        ReportingEvents::BackfillService.backfill_date(account, date)

        # Update progress
        days_processed += 1
        percentage = (days_processed.to_f / total_days * 100).round(1)

        # Print on same line with carriage return
        print "\r#{date} | #{days_processed}/#{total_days} days | #{percentage}%    "
        $stdout.flush
      end
    rescue StandardError => e
      # Fail fast: show error and exit immediately
      puts "\n\n"
      puts '=' * 70
      puts '❌ BACKFILL FAILED'
      puts '=' * 70
      puts "Error processing date: #{date}"
      puts "Error: #{e.class.name} - #{e.message}"
      puts ''
      puts 'Stack trace:'
      puts e.backtrace.first(10).map { |line| "  #{line}" }.join("\n")
      puts ''
      puts "Processed: #{days_processed}/#{total_days} days (#{(days_processed.to_f / total_days * 100).round(1)}%)"
      puts '=' * 70
      exit(1)
    end

    # 12. SUCCESS SUMMARY
    elapsed_time = Time.current - start_time
    avg_time_per_day = (elapsed_time / days_processed).round(3)

    puts "\n\n"
    puts '=' * 70
    puts '✅ BACKFILL COMPLETE'
    puts '=' * 70
    puts "Total Days Processed: #{days_processed}"
    puts "Total Time:           #{elapsed_time.round(2)} seconds"
    puts "Average per Day:      #{avg_time_per_day} seconds"
    puts ''
    puts 'Next steps:'
    puts "1. Enable feature flag: Account.find(#{account_id}).enable_features!('reporting_events_rollup')"
    puts '2. Verify rollups in database:'
    puts "   ReportingEventsRollup.where(account_id: #{account_id}).count"
    puts '3. Test reports to compare rollup vs raw performance'
    puts '=' * 70
  end
end
