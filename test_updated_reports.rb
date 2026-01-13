# Test script for updated report jobs using V2::CustomReportBuilder
# Generates reports for specified account and time period
# Supports two modes: Month Mode and Date Range Mode
# Usage:
#   Month Mode: rails runner test_updated_reports.rb <account_id> <year> <month1> [month2] [month3] ...
#   Date Range Mode: rails runner test_updated_reports.rb <account_id> --from <start_date> --to <end_date>

require 'csv'
require 'fileutils'
require 'date'

# Helper function to show usage
def show_usage # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
  puts '❌ Error: Invalid arguments'
  puts ''
  puts 'This script supports two modes:'
  puts ''
  puts '1. MONTH MODE - Generate reports for full calendar months'
  puts '   Usage: rails runner test_updated_reports.rb <account_id> <year> <month1> [month2] ... [--report <type>]'
  puts ''
  puts '   Arguments:'
  puts '     account_id  - The account ID to generate reports for'
  puts '     year        - The year (e.g., 2025)'
  puts '     month(s)    - One or more months (1-12)'
  puts '     --report    - (Optional) Report type: inbox, agent, or bot. Defaults to all reports.'
  puts ''
  puts '   Examples:'
  puts '     rails runner test_updated_reports.rb 702 2025 11'
  puts '     rails runner test_updated_reports.rb 702 2025 11 --report inbox'
  puts '     rails runner test_updated_reports.rb 702 2025 7 8 9 10'
  puts '     rails runner test_updated_reports.rb 702 2025 7 8 9 10 --report agent'
  puts ''
  puts '2. DATE RANGE MODE - Generate reports for a custom date range'
  puts '   Usage: rails runner test_updated_reports.rb <account_id> --from <start_date> --to <end_date> [--report <type>]'
  puts ''
  puts '   Arguments:'
  puts '     account_id  - The account ID to generate reports for'
  puts '     --from      - Start date in YYYY-MM-DD format'
  puts '     --to        - End date in YYYY-MM-DD format'
  puts '     --report    - (Optional) Report type: inbox, agent, or bot. Defaults to all reports.'
  puts ''
  puts '   Examples:'
  puts '     rails runner test_updated_reports.rb 702 --from 2025-11-01 --to 2025-11-15'
  puts '     rails runner test_updated_reports.rb 702 --from 2025-11-01 --to 2025-11-15 --report bot'
  puts '     rails runner test_updated_reports.rb 702 --from 2025-10-15 --to 2025-12-05 --report inbox'
  puts ''
  exit 1
end

# Parse command line arguments
show_usage if ARGV.length < 3

account_id = ARGV[0].to_i

# Validate account_id
if account_id <= 0
  puts "❌ Error: Invalid account_id '#{ARGV[0]}'. Must be a positive integer."
  exit 1
end

# Parse optional --report flag
report_type = nil
if ARGV.include?('--report')
  report_index = ARGV.index('--report')
  if ARGV[report_index + 1].nil?
    puts '❌ Error: --report flag must be followed by a report type (inbox, agent, or bot)'
    show_usage
  end

  report_type = ARGV[report_index + 1].downcase
  unless %w[inbox agent bot].include?(report_type)
    puts "❌ Error: Invalid report type '#{report_type}'. Must be one of: inbox, agent, bot"
    exit 1
  end
end

# Detect mode based on presence of --from and --to flags
date_range_mode = ARGV.include?('--from') && ARGV.include?('--to')

# Variables for both modes
month_ranges = []
mode_description = ''

if date_range_mode
  # DATE RANGE MODE
  from_index = ARGV.index('--from')
  to_index = ARGV.index('--to')

  if from_index.nil? || to_index.nil? || ARGV[from_index + 1].nil? || ARGV[to_index + 1].nil?
    puts '❌ Error: Both --from and --to flags must be followed by a date'
    show_usage
  end

  from_date_str = ARGV[from_index + 1]
  to_date_str = ARGV[to_index + 1]

  # Parse and validate dates
  begin
    from_date = Date.parse(from_date_str)
    to_date = Date.parse(to_date_str)
  rescue ArgumentError
    puts '❌ Error: Invalid date format. Use YYYY-MM-DD format.'
    puts "  From date: #{from_date_str}"
    puts "  To date: #{to_date_str}"
    exit 1
  end

  # Validate date range
  if to_date < from_date
    puts "❌ Error: End date (#{to_date_str}) must be after start date (#{from_date_str})"
    exit 1
  end

  # Create single range for custom dates
  start_of_range = Time.zone.parse(from_date_str).beginning_of_day
  end_of_range = Time.zone.parse(to_date_str).end_of_day

  month_ranges << {
    month_name: "Custom Range: #{from_date_str} to #{to_date_str}",
    month_short: "#{from_date_str}_to_#{to_date_str}",
    since: start_of_range,
    until: end_of_range
  }

  mode_description = 'Date Range Mode'
else
  # MONTH MODE (existing behavior)
  show_usage if ARGV.length < 3

  year = ARGV[1].to_i
  months = ARGV[2..].map(&:to_i)

  # Validate year
  if year < 1900 || year > 2100
    puts "❌ Error: Invalid year '#{year}'. Must be between 1900 and 2100."
    exit 1
  end

  # Validate months
  invalid_months = months.select { |m| m < 1 || m > 12 }
  if invalid_months.any?
    puts "❌ Error: Invalid month(s): #{invalid_months.join(', ')}. Months must be between 1 and 12."
    exit 1
  end

  # Generate date ranges for specified months
  months.sort.each do |month|
    start_of_month = Time.zone.local(year, month, 1).beginning_of_day
    end_of_month = start_of_month.end_of_month.end_of_day

    month_ranges << {
      month_name: start_of_month.strftime('%B %Y'),
      month_short: start_of_month.strftime('%Y-%m'),
      since: start_of_month,
      until: end_of_month
    }
  end

  mode_description = 'Month Mode'
end

puts '=' * 80
puts 'Testing Updated Report Jobs with V2::CustomReportBuilder'
puts '=' * 80

month_names = month_ranges.pluck(:month_name).join(', ')

puts "\nTest Configuration:"
puts "  Mode: #{mode_description}"
puts "  Account ID: #{account_id}"
puts "  Report Type: #{report_type ? report_type.capitalize : 'All reports (inbox, agent, bot)'}"

if date_range_mode
  puts "  Date Range: #{month_ranges.first[:month_name].sub('Custom Range: ', '')}"
else
  puts "  Year: #{year}"
  puts "  Months: #{month_names}"
  puts "  Total months to process: #{month_ranges.length}"
end

puts "  Output Directory: #{Dir.pwd}"

all_generated_files = []
all_uploaded_urls = []

# Helper method to upload CSV to ActiveStorage
def upload_to_storage(_account_id, file_name, csv_content)
  puts '  📤 Uploading to storage...'
  blob = ActiveStorage::Blob.create_and_upload!(
    io: StringIO.new(csv_content),
    filename: file_name,
    content_type: 'text/csv'
  )

  csv_url = Rails.application.routes.url_helpers.url_for(blob)
  puts '  ✅ Uploaded successfully'
  csv_url
rescue StandardError => e
  puts "  ❌ Upload failed: #{e.message}"
  nil
end

# rubocop:disable Metrics/BlockLength
# Process each month
month_ranges.each_with_index do |month_data, index|
  puts "\n#{'=' * 80}"
  puts "Processing: #{month_data[:month_name]} (#{index + 1}/#{month_ranges.length})"
  puts('=' * 80)

  range = {
    since: month_data[:since],
    until: month_data[:until]
  }

  start_date = range[:since].strftime('%Y-%m-%d')
  end_date = range[:until].strftime('%Y-%m-%d')

  # Test 1: Inbox Channel Report
  if report_type.nil? || report_type == 'inbox'
    puts "\n[1/3] Generating Inbox Channel Report..."
    begin
      job = WeeklyInboxChannelReportJob.new
      job.send(:set_statement_timeout)

      start_time = Time.current
      report = job.send(:generate_report, account_id, range)
      duration = ((Time.current - start_time) * 1000).round(2)

      if report.any?
        csv_content = job.send(:generate_csv, report, start_date, end_date, account_id)
        file_name = "inbox_channel_report_#{account_id}_#{month_data[:month_short]}.csv"

        # Save locally
        File.write(file_name, csv_content)
        all_generated_files << file_name

        # Upload to storage
        csv_url = upload_to_storage(account_id, file_name, csv_content)
        all_uploaded_urls << { name: file_name, url: csv_url, type: 'Inbox Channel Report' } if csv_url

        puts "  ✅ Success (#{duration}ms) - #{report.length} inboxes - Saved: #{file_name}"
      else
        puts '  ⚠️  No data for this month'
      end
    rescue StandardError => e
      puts "  ❌ Error: #{e.message}"
    end
  end

  # Test 2: Agent Level Report
  if report_type.nil? || report_type == 'agent'
    puts '[2/3] Generating Agent Level Report...'
    begin
      job = WeeklyAgentLevelReportJob.new
      job.send(:set_statement_timeout)

      start_time = Time.current
      report = job.send(:generate_report, account_id, range)
      duration = ((Time.current - start_time) * 1000).round(2)

      if report.any?
        csv_content = job.send(:generate_csv, report, start_date, end_date, account_id)
        file_name = "agent_level_report_#{account_id}_#{month_data[:month_short]}.csv"

        # Save locally
        File.write(file_name, csv_content)
        all_generated_files << file_name

        # Upload to storage
        csv_url = upload_to_storage(account_id, file_name, csv_content)
        all_uploaded_urls << { name: file_name, url: csv_url, type: 'Agent Level Report' } if csv_url

        puts "  ✅ Success (#{duration}ms) - #{report.length} agent-inbox combos - Saved: #{file_name}"
      else
        puts '  ⚠️  No data for this month'
      end
    rescue StandardError => e
      puts "  ❌ Error: #{e.message}"
    end
  end

  # Test 3: Bot Report
  next unless report_type.nil? || report_type == 'bot'

  puts '[3/3] Generating Bot Report...'
  begin
    job = WeeklyBotReportJob.new
    job.send(:set_statement_timeout)

    start_time = Time.current
    report = job.send(:generate_report, account_id, range)
    duration = ((Time.current - start_time) * 1000).round(2)

    if report.any?
      csv_content = job.send(:generate_csv, report, start_date, end_date, account_id)
      file_name = "bot_report_#{account_id}_#{month_data[:month_short]}.csv"

      # Save locally
      File.write(file_name, csv_content)
      all_generated_files << file_name

      # Upload to storage
      csv_url = upload_to_storage(account_id, file_name, csv_content)
      all_uploaded_urls << { name: file_name, url: csv_url, type: 'Bot Report' } if csv_url

      puts "  ✅ Success (#{duration}ms) - #{report.length} bot-inbox combos - Saved: #{file_name}"
    else
      puts '  ⚠️  No data for this month'
    end
  rescue StandardError => e
    puts "  ❌ Error: #{e.message}"
  end
end
# rubocop:enable Metrics/BlockLength

puts "\n#{'=' * 80}"
if report_type
  puts "#{report_type.capitalize} Reports Generated!"
else
  puts 'All Reports Generated!'
end
puts('=' * 80)

puts "\n📁 Generated Files (#{all_generated_files.length} total):"
all_generated_files.each do |file|
  puts "  ✓ #{file} (#{(File.size(file) / 1024.0).round(2)} KB)"
end

if all_uploaded_urls.any?
  puts "\n#{'=' * 80}"
  puts '🔗 Uploaded Report Links'
  puts('=' * 80)
  puts "\n✅ All reports have been uploaded to storage. Access them using the links below:\n\n"

  all_uploaded_urls.each_with_index do |upload_info, index|
    puts "#{index + 1}. #{upload_info[:type]}"
    puts "   File: #{upload_info[:name]}"
    puts "   URL: #{upload_info[:url]}"
    puts ''
  end
else
  puts "\n⚠️  No reports were uploaded (all reports had no data or upload failed)"
end

if date_range_mode
  puts "\n📊 Summary:"
  puts "  Date Range: #{month_ranges.first[:month_name].sub('Custom Range: ', '')}"
  puts "  Total reports generated: #{all_generated_files.length}"
  puts "  Total reports uploaded: #{all_uploaded_urls.length}"
else
  puts "\n📊 Summary by Month:"
  month_ranges.each do |month_data|
    month_files = all_generated_files.select { |f| f.include?(month_data[:month_short]) }
    puts "  #{month_data[:month_name]}: #{month_files.length} reports"
  end
  puts "\n  Total reports uploaded: #{all_uploaded_urls.length}"
end

puts "\n✅ Test Complete!"
