# frozen_string_literal: true

namespace :reporting_events_rollup do
  desc 'Backfill rollup table from historical reporting events'
  task backfill: :environment do
    ReportingEventsRollupBackfill.new.run
  end
end

class ReportingEventsRollupBackfill # rubocop:disable Metrics/ClassLength
  def run
    print_header
    account = prompt_account
    timezone = prompt_timezone
    first_event, last_event = discover_events(account)
    start_date, end_date, total_days = resolve_date_range(account, timezone, first_event, last_event)
    dry_run = prompt_dry_run?
    print_plan(account, timezone, start_date, end_date, total_days, first_event, last_event, dry_run)
    return if dry_run

    confirm_and_execute(account, timezone, start_date, end_date, total_days)
  end

  private

  def print_header
    puts ''
    puts '=' * 70
    puts 'Reporting Events Rollup Backfill'
    puts '=' * 70
    puts ''
  end

  def prompt_account
    print 'Enter Account ID: '
    account_id = $stdin.gets.chomp
    abort 'Error: Account ID is required' if account_id.blank?

    account = Account.find_by(id: account_id)
    abort "Error: Account with ID #{account_id} not found" unless account

    puts "Found account: #{account.name}"
    puts ''
    account
  end

  def prompt_timezone
    print 'Enter UTC offset (e.g., +5:30, -4, 0): '
    offset_input = $stdin.gets.chomp
    abort 'Error: UTC offset is required' if offset_input.blank?

    matching_zones = find_matching_zones(offset_input)
    abort "Error: No timezones found for offset '#{offset_input}'" if matching_zones.empty?

    display_matching_zones(matching_zones, offset_input)
    select_timezone(matching_zones)
  end

  def display_matching_zones(zones, offset_input)
    puts ''
    puts "Timezones matching UTC#{offset_input}:"
    puts ''
    zones.each_with_index { |tz, i| puts "  #{i + 1}. #{tz.name} (#{tz.tzinfo.identifier})" }
    puts ''
  end

  def select_timezone(zones)
    print "Select timezone (1-#{zones.size}): "
    selection = $stdin.gets.chomp.to_i
    abort 'Error: Invalid selection' if selection < 1 || selection > zones.size

    timezone = zones[selection - 1].tzinfo.identifier
    puts "Selected timezone: #{timezone}"
    timezone
  end

  def find_matching_zones(offset_input)
    normalized = offset_input.gsub(/^(?!\+|-)/, '+')
    parts = normalized.split(':')
    hours = parts[0].to_i
    minutes = (parts[1] || '0').to_i
    total_seconds = (hours * 3600) + (hours.negative? ? -minutes * 60 : minutes * 60)

    ActiveSupport::TimeZone.all.select { |tz| tz.utc_offset == total_seconds }
  end

  def discover_events(account)
    first_event = account.reporting_events.order(:created_at).first
    last_event = account.reporting_events.order(:created_at).last

    if first_event.nil?
      puts ''
      puts "No reporting events found for account #{account.id}"
      puts 'Nothing to backfill.'
      exit(0)
    end

    [first_event, last_event]
  end

  def resolve_date_range(account, timezone, first_event, last_event)
    tz = ActiveSupport::TimeZone[timezone]
    discovered_start = first_event.created_at.in_time_zone(tz).to_date
    discovered_end = last_event.created_at.in_time_zone(tz).to_date
    discovered_days = (discovered_end - discovered_start).to_i + 1

    puts "Discovered date range: #{discovered_start} to #{discovered_end} (#{discovered_days} days) [Account: #{account.name}]"
    puts ''

    start_date, end_date = prompt_date_override(discovered_start, discovered_end)
    total_days = (end_date - start_date).to_i + 1
    [start_date, end_date, total_days]
  end

  def prompt_date_override(discovered_start, discovered_end)
    print 'Override date range? (y/N): '
    override = $stdin.gets.chomp.downcase

    if %w[y yes].include?(override)
      print 'Enter start date (YYYY-MM-DD): '
      start_input = $stdin.gets.chomp
      start_date = start_input.present? ? start_input.to_date : discovered_start

      print 'Enter end date (YYYY-MM-DD): '
      end_input = $stdin.gets.chomp
      end_date = end_input.present? ? end_input.to_date : discovered_end
      [start_date, end_date]
    else
      [discovered_start, discovered_end]
    end
  end

  def prompt_dry_run?
    print 'Dry run? (y/N): '
    input = $stdin.gets.chomp.downcase
    puts ''
    %w[y yes].include?(input)
  end

  # rubocop:disable Metrics/ParameterLists
  def print_plan(account, timezone, start_date, end_date, total_days, first_event, last_event, dry_run)
    zone = ActiveSupport::TimeZone[timezone]
    print_plan_summary(account, timezone, start_date, end_date, total_days, zone, first_event, last_event, dry_run)

    return unless dry_run

    puts "DRY RUN MODE: Would process #{total_days} days"
    puts "Would set reporting_timezone to '#{timezone}'"
    puts 'Run without dry run to execute backfill'
  end
  # rubocop:enable Metrics/ParameterLists

  def print_plan_summary(account, timezone, start_date, end_date, total_days, zone, first_event, last_event, dry_run) # rubocop:disable Metrics/ParameterLists
    puts '=' * 70
    puts 'Backfill Plan Summary'
    puts '=' * 70
    puts "Account:     #{account.name} (ID: #{account.id})"
    puts "Timezone:    #{timezone}"
    puts "Date Range:  #{start_date} to #{end_date} (#{total_days} days)"
    puts "First Event: #{format_event_time(first_event, zone)}"
    puts "Last Event:  #{format_event_time(last_event, zone)}"
    puts "Dry Run:     #{dry_run ? 'YES (no data will be written)' : 'NO'}"
    puts '=' * 70
    puts ''
  end

  def format_event_time(event, zone)
    event.created_at.in_time_zone(zone).strftime('%Y-%m-%d %H:%M:%S %Z')
  end

  def confirm_and_execute(account, timezone, start_date, end_date, total_days)
    if total_days > 730
      puts "WARNING: Large backfill detected (#{total_days} days / #{(total_days / 365.0).round(1)} years)"
      puts ''
    end

    print 'Proceed with backfill? (y/N): '
    confirm = $stdin.gets.chomp.downcase
    abort 'Backfill cancelled' unless %w[y yes].include?(confirm)

    puts ''
    account.update!(reporting_timezone: timezone)
    puts "Set reporting_timezone to '#{timezone}' for account '#{account.name}'"
    puts ''

    execute_backfill(account, start_date, end_date, total_days)
  end

  def execute_backfill(account, start_date, end_date, total_days)
    puts 'Processing dates...'
    puts ''

    start_time = Time.current
    days_processed = 0

    (start_date..end_date).each do |date|
      ReportingEvents::BackfillService.backfill_date(account, date)
      days_processed += 1
      percentage = (days_processed.to_f / total_days * 100).round(1)
      print "\r#{date} | #{days_processed}/#{total_days} days | #{percentage}%    "
      $stdout.flush
    end

    print_success(account, days_processed, total_days, Time.current - start_time)
  rescue StandardError => e
    print_failure(e, days_processed, total_days)
  end

  def print_success(account, days_processed, _total_days, elapsed_time)
    puts "\n\n"
    puts '=' * 70
    puts 'BACKFILL COMPLETE'
    puts '=' * 70
    puts "Total Days Processed: #{days_processed}"
    puts "Total Time:           #{elapsed_time.round(2)} seconds"
    puts "Average per Day:      #{(elapsed_time / days_processed).round(3)} seconds"
    puts ''
    puts 'Next steps:'
    puts "1. Enable feature flag: Account.find(#{account.id}).enable_features!('reporting_events_rollup')"
    puts '2. Verify rollups in database:'
    puts "   ReportingEventsRollup.where(account_id: #{account.id}).count"
    puts '3. Test reports to compare rollup vs raw performance'
    puts '=' * 70
  end

  def print_failure(error, days_processed, total_days)
    puts "\n\n"
    puts '=' * 70
    puts 'BACKFILL FAILED'
    puts '=' * 70
    print_error_details(error)
    print_progress(days_processed, total_days)
    exit(1)
  end

  def print_error_details(error)
    puts "Error: #{error.class.name} - #{error.message}"
    puts ''
    puts 'Stack trace:'
    puts error.backtrace.first(10).map { |line| "  #{line}" }.join("\n")
    puts ''
  end

  def print_progress(days_processed, total_days)
    percentage = (days_processed.to_f / total_days * 100).round(1)
    puts "Processed: #{days_processed}/#{total_days} days (#{percentage}%)"
    puts '=' * 70
  end
end
