# frozen_string_literal: true

namespace :reporting_events_rollup do
  desc 'Interactively set account.reporting_timezone and show recommended backfill run times'
  task set_timezone: :environment do
    ReportingEventsRollupTimezoneSetup.new.run
  end
end

class ReportingEventsRollupTimezoneSetup
  def run
    print_header
    account = prompt_account
    print_current_timezone(account)
    timezone = prompt_timezone
    confirm_and_update(account, timezone)
    print_next_steps(account, timezone)
  end

  private

  def print_header
    puts ''
    puts color('=' * 70, :cyan)
    puts color('Reporting Events Rollup Timezone Setup', :bold, :cyan)
    puts color('=' * 70, :cyan)
    puts color('Help:', :bold, :yellow)
    puts '1. This task writes a valid account.reporting_timezone.'
    puts '2. Backfill uses this timezone and skips today by default.'
    puts '3. Run backfill only after the account timezone day closes.'
    puts ''
  end

  def prompt_account
    print 'Enter Account ID: '
    account_id = $stdin.gets.chomp
    abort color('Error: Account ID is required', :red, :bold) if account_id.blank?

    account = Account.find_by(id: account_id)
    abort color("Error: Account with ID #{account_id} not found", :red, :bold) unless account

    puts color("Found account: #{account.name}", :gray)
    puts ''
    account
  end

  def print_current_timezone(account)
    current_timezone = account.reporting_timezone.presence || '(not set)'
    puts color("Current reporting_timezone: #{current_timezone}", :gray)
    puts ''
  end

  def prompt_timezone
    loop do
      print 'Enter UTC offset to pick timezone (e.g., +5:30, -8, 0): '
      offset_input = $stdin.gets.chomp
      abort color('Error: UTC offset is required', :red, :bold) if offset_input.blank?

      matching_zones = find_matching_zones(offset_input)
      abort color("Error: No timezones found for offset '#{offset_input}'", :red, :bold) if matching_zones.empty?

      display_matching_zones(matching_zones, offset_input)
      timezone = select_timezone(matching_zones)
      return timezone if timezone.present?
    end
  end

  def find_matching_zones(offset_input)
    total_seconds = utc_offset_in_seconds(offset_input)
    return [] unless total_seconds

    ActiveSupport::TimeZone.all.select { |tz| tz.utc_offset == total_seconds }
  end

  def utc_offset_in_seconds(offset_input)
    normalized = offset_input.strip
    return unless normalized.match?(/\A[+-]?\d{1,2}(:\d{2})?\z/)

    sign = normalized.start_with?('-') ? -1 : 1
    raw = normalized.delete_prefix('+').delete_prefix('-')
    hours_part, minutes_part = raw.split(':', 2)

    hours = Integer(hours_part, 10)
    minutes = Integer(minutes_part || '0', 10)
    return unless minutes.between?(0, 59)

    total_minutes = (hours * 60) + minutes
    return if total_minutes > max_utc_offset_minutes(sign)

    sign * total_minutes * 60
  rescue ArgumentError
    nil
  end

  def max_utc_offset_minutes(sign)
    sign.negative? ? 12 * 60 : 14 * 60
  end

  def display_matching_zones(zones, offset_input)
    puts ''
    puts color("Timezones matching UTC#{offset_input}:", :yellow, :bold)
    puts ''
    zones.each_with_index do |tz, index|
      puts "  #{index + 1}. #{tz.name} (#{tz.tzinfo.identifier})"
    end
    puts '  0. Re-enter UTC offset'
    puts ''
  end

  def select_timezone(zones)
    print "Select timezone (1-#{zones.size}, 0 to go back): "
    selection = $stdin.gets.chomp.to_i
    return if selection.zero?

    abort color('Error: Invalid selection', :red, :bold) if selection < 1 || selection > zones.size

    timezone = zones[selection - 1].tzinfo.identifier
    puts color("Selected timezone: #{timezone}", :gray)
    puts ''
    timezone
  end

  def confirm_and_update(account, timezone)
    print "Update account #{account.id} reporting_timezone to '#{timezone}'? (y/N): "
    confirm = $stdin.gets.chomp.downcase
    abort 'Timezone setup cancelled' unless %w[y yes].include?(confirm)

    account.update!(reporting_timezone: timezone)
    puts ''
    puts color("Updated reporting_timezone for account '#{account.name}' to '#{timezone}'", :green, :bold)
    puts ''
  end

  def print_next_steps(account, timezone)
    run_times = recommended_run_times(timezone)
    print_next_steps_header
    print_next_steps_schedule(timezone, run_times)
    print_next_steps_backfill(account)
    puts color('=' * 70, :green)
  end

  def print_next_steps_header
    puts color('=' * 70, :green)
    puts color('Next Steps', :bold, :green)
    puts color('=' * 70, :green)
  end

  def print_next_steps_schedule(timezone, run_times)
    puts "1. Wait for today's day-boundary to pass in #{timezone}."
    puts '2. Recommended earliest backfill start time:'
    puts "   - #{timezone}: #{format_time(run_times[:account_tz])}"
    puts "   - UTC:        #{format_time(run_times[:utc])}"
    puts "   - IST:        #{format_time(run_times[:ist])}"
    puts "   - PCT/PT:     #{format_time(run_times[:pct])}"
  end

  def print_next_steps_backfill(account)
    puts '3. Run backfill:'
    puts '   bundle exec rake reporting_events_rollup:backfill'
    puts "4. Backfill will use account.reporting_timezone and skip today by default for account #{account.id}."
  end

  def recommended_run_times(timezone)
    account_zone = ActiveSupport::TimeZone[timezone]
    next_day = Time.current.in_time_zone(account_zone).to_date + 1.day
    account_time = account_zone.parse(next_day.to_s) + 30.minutes

    {
      account_tz: account_time,
      utc: account_time.in_time_zone('UTC'),
      ist: account_time.in_time_zone('Asia/Kolkata'),
      pct: account_time.in_time_zone('Pacific Time (US & Canada)')
    }
  end

  def format_time(time)
    time.strftime('%Y-%m-%d %H:%M:%S %Z')
  end

  ANSI_COLORS = {
    reset: "\e[0m",
    bold: "\e[1m",
    red: "\e[31m",
    green: "\e[32m",
    yellow: "\e[33m",
    cyan: "\e[36m",
    gray: "\e[90m"
  }.freeze

  def color(text, *styles)
    return text unless $stdout.tty?

    codes = styles.filter_map { |style| ANSI_COLORS[style] }.join
    "#{codes}#{text}#{ANSI_COLORS[:reset]}"
  end
end
