require 'json'
require 'csv'

class HourlyChatReportJob < ApplicationJob
  queue_as :scheduled_jobs

  JOB_DATA_URL = 'https://bitespeed-app.s3.us-east-1.amazonaws.com/InternalAccess/cw-auto-conversation-report.json'.freeze

  def perform
    Rails.logger.info "Starting HourlyChatReportJob at #{Time.current}"
    set_statement_timeout

    # Hardcoded test data
    job_data = [
      {
        account_id: 2077,
        frequency: 'daily'
      }
    ]

    # Uncomment below to fetch from S3 in production
    # Rails.logger.info "Fetching job data from URL: #{JOB_DATA_URL}"
    # response = HTTParty.get(JOB_DATA_URL)
    # job_data = JSON.parse(response.body, symbolize_names: true)
    # job_data = job_data[:hourly_chat_report]

    Rails.logger.info "Found #{job_data.length} jobs to process"

    job_data.each do |job|
      process_job(job)
    end

    Rails.logger.info "Completed HourlyChatReportJob at #{Time.current}"
  end

  private

  def process_job(job)
    Rails.logger.info "Processing job for account_id: #{job[:account_id]}, frequency: #{job[:frequency]}"

    # Validate frequency - hourly reports should only run daily
    if job[:frequency] != 'daily'
      Rails.logger.info "Skipping job - frequency '#{job[:frequency]}' not supported for hourly reports"
      return
    end

    # Generate report for yesterday (in IST timezone to match SQL query)
    range = {
      since: 1.day.ago.beginning_of_day.in_time_zone('Asia/Kolkata'),
      until: 1.day.ago.end_of_day.in_time_zone('Asia/Kolkata')
    }

    Rails.logger.info "Processing account with range: #{range[:since]} to #{range[:until]}"
    process_account(job[:account_id], range)
  end

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '60s'")
  end

  def process_account(account_id, range)
    Rails.logger.info "Starting to process account_id: #{account_id}"

    report = generate_hourly_report(account_id, range)

    if report.present?
      Rails.logger.info "Data found for account_id: #{account_id} - #{report.length} hourly records"

      report_date = range[:since].to_date.strftime('%Y-%m-%d')

      Rails.logger.info "Generating CSV for account_id: #{account_id}"
      csv_content = generate_csv(report, report_date)
      Rails.logger.info "CSV generated for account_id: #{account_id} - #{csv_content.bytesize} bytes"

      upload_csv(account_id, report_date, csv_content)
    else
      Rails.logger.info "No data found for account_id: #{account_id}"
    end
  end

  # rubocop:disable Metrics/MethodLength
  def generate_hourly_report(account_id, range)
    Rails.logger.info "Generating hourly report for account_id: #{account_id} with range: #{range[:since]} to #{range[:until]}"

    sql = ActiveRecord::Base.send(:sanitize_sql_array, [<<-SQL.squish, { account_id: account_id, since: range[:since], until: range[:until] }])
      WITH hourly_data AS (
        SELECT generate_series(0, 23) AS hour
      ),
      assignments AS (
        SELECT
          EXTRACT(HOUR FROM created_at AT TIME ZONE 'Asia/Kolkata')::INTEGER AS hour,
          COUNT(DISTINCT conversation_id) AS assigned_count
        FROM conversation_assignments
        WHERE account_id = :account_id
          AND created_at BETWEEN :since AND :until
          AND assignee_id IN (
            SELECT id FROM users
            WHERE name IS NULL OR name != 'BiteSpeed Bot'
          )
        GROUP BY EXTRACT(HOUR FROM created_at AT TIME ZONE 'Asia/Kolkata')::INTEGER
      ),
      resolutions AS (
        SELECT
          EXTRACT(HOUR FROM created_at AT TIME ZONE 'Asia/Kolkata')::INTEGER AS hour,
          COUNT(*) AS resolved_count
        FROM reporting_events
        WHERE account_id = :account_id
          AND name = 'conversation_resolved'
          AND created_at BETWEEN :since AND :until
        GROUP BY EXTRACT(HOUR FROM created_at AT TIME ZONE 'Asia/Kolkata')::INTEGER
      )
      SELECT
        h.hour,
        COALESCE(a.assigned_count, 0) AS chats_assigned,
        COALESCE(r.resolved_count, 0) AS chats_resolved
      FROM hourly_data h
      LEFT JOIN assignments a ON h.hour = a.hour
      LEFT JOIN resolutions r ON h.hour = r.hour
      ORDER BY h.hour
    SQL

    result = ActiveRecord::Base.connection.exec_query(sql).to_a
    Rails.logger.info "Hourly report generated for account_id: #{account_id} - #{result.length} records found"
    result
  end
  # rubocop:enable Metrics/MethodLength

  def generate_csv(results, report_date) # rubocop:disable Metrics/MethodLength
    CSV.generate(headers: true) do |csv|
      csv << ["Hourly Chat Report - #{report_date}"]
      csv << []

      # Hourly breakdown
      csv << ['Hour', 'Chats Assigned', 'Chats Resolved']

      total_assigned = 0
      total_resolved = 0

      results.each do |row|
        hour = row['hour'].to_i
        assigned = row['chats_assigned'].to_i
        resolved = row['chats_resolved'].to_i

        total_assigned += assigned
        total_resolved += resolved

        hour_label = format('%<hour>02d:00', hour: hour)
        csv << [hour_label, assigned, resolved]
      end

      csv << []
      csv << ['Summary']
      csv << ['Total Assigned', total_assigned]
      csv << ['Total Resolved', total_resolved]
    end
  end

  def upload_csv(account_id, report_date, csv_content)
    Rails.logger.info "Starting CSV upload for account_id: #{account_id}, date: #{report_date}"

    file_name = "hourly_chat_report_#{account_id}_#{report_date}.csv"
    Rails.logger.info "File name: #{file_name}"

    csv_url = upload_to_storage(account_id, file_name, csv_content)
    send_email_notification(account_id, csv_url, report_date)

    Rails.logger.info "Email sent successfully for account_id: #{account_id}"
  end

  def upload_to_storage(account_id, file_name, csv_content)
    Rails.logger.info "Creating ActiveStorage blob for account_id: #{account_id}"
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(csv_content),
      filename: file_name,
      content_type: 'text/csv'
    )

    csv_url = Rails.application.routes.url_helpers.url_for(blob)
    Rails.logger.info "CSV uploaded successfully for account_id: #{account_id}, URL: #{csv_url}"
    csv_url
  end

  def send_email_notification(account_id, csv_url, report_date)
    Rails.logger.info "Sending email notification for account_id: #{account_id}"
    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: Account.find(account_id))
    mailer.hourly_chat_report(csv_url, report_date).deliver_now
  end
end
