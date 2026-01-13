require 'json'
require 'csv'

# Daily job that generates and emails three reports for the previous day:
# 1. Inbox Channel Report
# 2. Agent Level Report
# 3. Bot Report
#
# All three reports are sent in a single email with CSV download links
class DailyCombinedReportsJob < ApplicationJob
  queue_as :scheduled_jobs

  # Add account IDs that need daily combined reports
  ACCOUNT_CONFIGS = [
    {
      account_id: 1734,
      recipient_emails: [
        'athuldas@mydesignation.com',
        'divyavaralakshmi@mydesignation.com',
        'jay@procedure.tech'
      ]
    }
  ].freeze

  def perform
    Rails.logger.info "Starting DailyCombinedReportsJob at #{Time.current}"
    set_statement_timeout

    ACCOUNT_CONFIGS.each do |config|
      process_account(config)
    end

    Rails.logger.info "DailyCombinedReportsJob completed successfully at #{Time.current}"
  end

  private

  def process_account(config) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    account_id = config[:account_id]
    recipient_emails = config[:recipient_emails]

    Rails.logger.info "Processing daily combined reports for account_id: #{account_id}"

    # IST timezone
    ist_zone = ActiveSupport::TimeZone.new('Asia/Kolkata')

    # Yesterday in IST (00:00:00 to 23:59:59)
    yesterday = ist_zone.now.yesterday
    range = {
      since: yesterday.beginning_of_day,
      until: yesterday.end_of_day
    }

    Rails.logger.info "Processing account with range: #{range[:since]} to #{range[:until]}"

    # Generate all three reports
    csv_urls = {}
    report_date = range[:since].strftime('%Y-%m-%d')

    # 1. Inbox Channel Report
    csv_urls[:inbox_channel] = generate_inbox_channel_report(account_id, range, report_date)

    # 2. Agent Level Report
    csv_urls[:agent_level] = generate_agent_level_report(account_id, range, report_date)

    # 3. Bot Report
    csv_urls[:bot] = generate_bot_report(account_id, range, report_date)

    # Filter out nil values (reports that had no data)
    csv_urls.compact!

    # Send combined email with all reports
    if csv_urls.any?
      send_combined_email(account_id, csv_urls, report_date, recipient_emails)
      Rails.logger.info "Successfully sent daily combined reports for account_id: #{account_id}"
    else
      Rails.logger.info "No reports generated for account_id: #{account_id} - no data for the period"
    end
  rescue StandardError => e
    Rails.logger.error "Error processing daily combined reports for account_id: #{account_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def generate_inbox_channel_report(account_id, range, report_date)
    Rails.logger.info "Generating Inbox Channel Report for account_id: #{account_id}"

    job = WeeklyInboxChannelReportJob.new
    job.send(:set_statement_timeout)

    report = job.send(:generate_report, account_id, range)

    if report.present?
      start_date = range[:since].strftime('%Y-%m-%d')
      end_date = range[:until].strftime('%Y-%m-%d')

      csv_content = job.send(:generate_csv, report, start_date, end_date, account_id)
      file_name = "daily_inbox_channel_report_#{account_id}_#{report_date}.csv"

      upload_to_storage(file_name, csv_content)
    else
      Rails.logger.info "No inbox channel data for account_id: #{account_id}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error generating inbox channel report: #{e.message}"
    nil
  end

  def generate_agent_level_report(account_id, range, report_date)
    Rails.logger.info "Generating Agent Level Report for account_id: #{account_id}"

    job = WeeklyAgentLevelReportJob.new
    job.send(:set_statement_timeout)

    report = job.send(:generate_report, account_id, range)

    if report.present?
      start_date = range[:since].strftime('%Y-%m-%d')
      end_date = range[:until].strftime('%Y-%m-%d')

      csv_content = job.send(:generate_csv, report, start_date, end_date, account_id)
      file_name = "daily_agent_level_report_#{account_id}_#{report_date}.csv"

      upload_to_storage(file_name, csv_content)
    else
      Rails.logger.info "No agent level data for account_id: #{account_id}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error generating agent level report: #{e.message}"
    nil
  end

  def generate_bot_report(account_id, range, report_date)
    Rails.logger.info "Generating Bot Report for account_id: #{account_id}"

    job = WeeklyBotReportJob.new
    job.send(:set_statement_timeout)

    report = job.send(:generate_report, account_id, range)

    if report.present?
      start_date = range[:since].strftime('%Y-%m-%d')
      end_date = range[:until].strftime('%Y-%m-%d')

      csv_content = job.send(:generate_csv, report, start_date, end_date, account_id)
      file_name = "daily_bot_report_#{account_id}_#{report_date}.csv"

      upload_to_storage(file_name, csv_content)
    else
      Rails.logger.info "No bot data for account_id: #{account_id}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error generating bot report: #{e.message}"
    nil
  end

  def upload_to_storage(file_name, csv_content)
    Rails.logger.info "Uploading to storage: #{file_name}"

    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(csv_content),
      filename: file_name,
      content_type: 'text/csv'
    )

    csv_url = Rails.application.routes.url_helpers.url_for(blob)
    Rails.logger.info "CSV uploaded successfully: #{csv_url}"
    csv_url
  end

  def send_combined_email(account_id, csv_urls, report_date, recipient_emails)
    Rails.logger.info "Sending combined email for account_id: #{account_id}"

    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: Account.find(account_id))
    mailer.daily_combined_reports(csv_urls, report_date, recipient_emails).deliver_now

    Rails.logger.info "Email sent successfully to #{recipient_emails.join(', ')}"
  end

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '60s'")
  end
end
