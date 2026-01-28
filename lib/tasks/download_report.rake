# Download Report Rake Tasks
#
# Usage:
#   POSTGRES_STATEMENT_TIMEOUT=600s NEW_RELIC_AGENT_ENABLED=false bundle exec rake download_report:agent
#   POSTGRES_STATEMENT_TIMEOUT=600s NEW_RELIC_AGENT_ENABLED=false bundle exec rake download_report:inbox
#   POSTGRES_STATEMENT_TIMEOUT=600s NEW_RELIC_AGENT_ENABLED=false bundle exec rake download_report:label
#
# The task will prompt for:
#   - Account ID
#   - Start Date (YYYY-MM-DD)
#   - End Date (YYYY-MM-DD)
#   - Timezone Offset (e.g., 0, 5.5, -5)
#   - Business Hours (y/n) - whether to use business hours for time metrics
#
# Output: <account_id>_<type>_<start_date>_<end_date>.csv

require 'csv'

# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ModuleLength
module DownloadReportTasks
  def self.prompt(message)
    print "#{message}: "
    $stdin.gets.chomp
  end

  def self.collect_params
    account_id = prompt('Enter Account ID')
    abort 'Error: Account ID is required' if account_id.blank?

    account = Account.find_by(id: account_id)
    abort "Error: Account with ID '#{account_id}' not found" unless account

    start_date = prompt('Enter Start Date (YYYY-MM-DD)')
    abort 'Error: Start date is required' if start_date.blank?

    end_date = prompt('Enter End Date (YYYY-MM-DD)')
    abort 'Error: End date is required' if end_date.blank?

    timezone_offset = prompt('Enter Timezone Offset (e.g., 0, 5.5, -5)')
    timezone_offset = timezone_offset.blank? ? 0 : timezone_offset.to_f

    business_hours = prompt('Use Business Hours? (y/n)')
    business_hours = business_hours.downcase == 'y'

    begin
      tz = ActiveSupport::TimeZone[timezone_offset]
      abort "Error: Invalid timezone offset '#{timezone_offset}'" unless tz

      since = tz.parse("#{start_date} 00:00:00").to_i.to_s
      until_date = tz.parse("#{end_date} 23:59:59").to_i.to_s
    rescue StandardError => e
      abort "Error parsing dates: #{e.message}"
    end

    {
      account: account,
      params: { since: since, until: until_date, timezone_offset: timezone_offset, business_hours: business_hours },
      start_date: start_date,
      end_date: end_date
    }
  end

  def self.save_csv(filename, headers, rows)
    CSV.open(filename, 'w') do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
    puts "Report saved to: #{filename}"
  end

  def self.format_time(seconds)
    return '' if seconds.nil? || seconds.zero?

    seconds.round(2)
  end

  def self.download_agent_report
    data = collect_params
    account = data[:account]

    puts "\nGenerating agent report..."
    builder = V2::Reports::AgentSummaryBuilder.new(account: account, params: data[:params])
    report = builder.build

    users = account.users.index_by(&:id)
    headers = %w[id name email conversations_count resolved_conversations_count avg_resolution_time avg_first_response_time avg_reply_time]

    rows = report.map do |row|
      user = users[row[:id]]
      [
        row[:id],
        user&.name || 'Unknown',
        user&.email || 'Unknown',
        row[:conversations_count],
        row[:resolved_conversations_count],
        format_time(row[:avg_resolution_time]),
        format_time(row[:avg_first_response_time]),
        format_time(row[:avg_reply_time])
      ]
    end

    filename = "#{account.id}_agent_#{data[:start_date]}_#{data[:end_date]}.csv"
    save_csv(filename, headers, rows)
  end

  def self.download_inbox_report
    data = collect_params
    account = data[:account]

    puts "\nGenerating inbox report..."
    builder = V2::Reports::InboxSummaryBuilder.new(account: account, params: data[:params])
    report = builder.build

    inboxes = account.inboxes.index_by(&:id)
    headers = %w[id name conversations_count resolved_conversations_count avg_resolution_time avg_first_response_time avg_reply_time]

    rows = report.map do |row|
      inbox = inboxes[row[:id]]
      [
        row[:id],
        inbox&.name || 'Unknown',
        row[:conversations_count],
        row[:resolved_conversations_count],
        format_time(row[:avg_resolution_time]),
        format_time(row[:avg_first_response_time]),
        format_time(row[:avg_reply_time])
      ]
    end

    filename = "#{account.id}_inbox_#{data[:start_date]}_#{data[:end_date]}.csv"
    save_csv(filename, headers, rows)
  end

  def self.download_label_report
    data = collect_params
    account = data[:account]

    puts "\nGenerating label report..."
    builder = V2::Reports::LabelSummaryBuilder.new(account: account, params: data[:params])
    report = builder.build

    headers = %w[id name conversations_count resolved_conversations_count avg_resolution_time avg_first_response_time avg_reply_time]

    rows = report.map do |row|
      [
        row[:id],
        row[:name],
        row[:conversations_count],
        row[:resolved_conversations_count],
        format_time(row[:avg_resolution_time]),
        format_time(row[:avg_first_response_time]),
        format_time(row[:avg_reply_time])
      ]
    end

    filename = "#{account.id}_label_#{data[:start_date]}_#{data[:end_date]}.csv"
    save_csv(filename, headers, rows)
  end
end
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ModuleLength

namespace :download_report do
  desc 'Download agent summary report as CSV'
  task agent: :environment do
    DownloadReportTasks.download_agent_report
  end

  desc 'Download inbox summary report as CSV'
  task inbox: :environment do
    DownloadReportTasks.download_inbox_report
  end

  desc 'Download label summary report as CSV'
  task label: :environment do
    DownloadReportTasks.download_label_report
  end
end
