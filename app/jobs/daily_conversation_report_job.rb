require 'json'
require 'csv'

# rubocop:disable Metrics/ClassLength
class DailyConversationReportJob < ApplicationJob
  queue_as :scheduled_jobs

  JOB_DATA_URL = 'https://bitespeed-app.s3.us-east-1.amazonaws.com/InternalAccess/cw-auto-conversation-report.json'.freeze

  def perform
    Rails.logger.info "Starting DailyConversationReportJob at #{Time.current}"
    set_statement_timeout

    # fetching the job data from the URL
    Rails.logger.info "Fetching job data from URL: #{JOB_DATA_URL}"
    response = HTTParty.get(JOB_DATA_URL)
    job_data = JSON.parse(response.body, symbolize_names: true)

    job_data = job_data[:daily_conversation_report]
    Rails.logger.info "Found #{job_data.length} jobs to process"

    job_data.each do |job|
      process_job(job)
    end

    Rails.logger.info "Completed DailyConversationReportJob at #{Time.current}"
  end

  def generate_custom_report(account_id, range, bitespeed_bot)
    Rails.logger.info "Starting custom report generation for account_id: #{account_id}"
    set_statement_timeout

    current_date = Date.current

    process_account(account_id, current_date, range, bitespeed_bot, 'custom', false)
    Rails.logger.info "Completed custom report generation for account_id: #{account_id}"
  end

  private

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  def process_job(job)
    Rails.logger.info "Processing job for account_id: #{job[:account_id]}, frequency: #{job[:frequency]}"

    current_date = Date.current
    current_day = current_date.wday

    report_time = job[:report_time]

    mask_data = job[:mask_data] || false
    created_at_flag = job[:CreatedAt] || false

    Rails.logger.info "Job config - report_time: #{report_time}, mask_data: #{mask_data}, created_at_flag: #{created_at_flag}"

    if report_time.present?
      report_time = Time.strptime(report_time, '%H:%M').in_time_zone('Asia/Kolkata').utc.strftime('%H:%M')
      current_time = Time.current.in_time_zone('UTC').strftime('%H:%M')

      report_minutes = report_time.split(':').map(&:to_i).inject(0) { |sum, n| (sum * 60) + n }
      current_minutes = current_time.split(':').map(&:to_i).inject(0) { |sum, n| (sum * 60) + n }

      Rails.logger.info "Time check - report_time: #{report_time}, current_time: #{current_time}, " \
                        "difference: #{(current_minutes - report_minutes).abs} minutes"

      # should trigger only when close to report_time (max 10 minutes difference)
      if (current_minutes - report_minutes).abs > 10
        Rails.logger.info 'Skipping job - time difference too large'
        return
      end
    end

    # should trigger only on 1st day of the month
    if job[:frequency] == 'monthly' && current_date.day != 1
      Rails.logger.info 'Skipping monthly job - not first day of month'
      return
    end

    # should trigger only on Mondays
    if job[:frequency] == 'weekly' && current_day != 1
      Rails.logger.info 'Skipping weekly job - not Monday'
      return
    end

    range = if job[:frequency] == 'monthly'
              { since: 1.month.ago.beginning_of_day, until: 1.day.ago.end_of_day }
            elsif job[:frequency] == 'weekly'
              { since: 1.week.ago.beginning_of_day, until: 1.day.ago.end_of_day }
            else
              { since: 24.hours.ago, until: Time.current }
            end

    Rails.logger.info "Processing account with range: #{range[:since]} to #{range[:until]}"
    process_account(job[:account_id], current_date, range, mask_data, false, job[:frequency], created_at_flag: created_at_flag)
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/MethodLength

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '60s'")
  end

  # rubocop:disable Metrics/ParameterLists
  def process_account(account_id, _current_date, range, mask_data, bitespeed_bot, frequency = 'daily', created_at_flag: false)
    Rails.logger.info "Starting to process account_id: #{account_id} with frequency: #{frequency}"

    report = generate_report(account_id, range, created_at_flag: created_at_flag)

    if report.present?
      Rails.logger.info "Data found for account_id: #{account_id} - #{report.length} records"

      start_date = range[:since].strftime('%Y-%m-%d')
      end_date = range[:until].strftime('%Y-%m-%d')

      Rails.logger.info "Generating CSV for account_id: #{account_id}"
      csv_content = generate_csv(report, start_date, end_date, mask_data)
      Rails.logger.info "CSV generated for account_id: #{account_id} - #{csv_content.bytesize} bytes"

      upload_csv(account_id, range, csv_content, frequency, bitespeed_bot)
    else
      Rails.logger.info "No data found for account_id: #{account_id}"
    end
  end
  # rubocop:enable Metrics/ParameterLists

  # rubocop:disable Metrics/MethodLength
  def generate_report(account_id, range, created_at_flag: false)
    Rails.logger.info "Generating report for account_id: #{account_id} with range: #{range[:since]} to #{range[:until]}"

    # Using ActiveRecord::Base directly for sanitization
    sql = ActiveRecord::Base.send(:sanitize_sql_array, [<<-SQL.squish, { account_id: account_id, since: range[:since], until: range[:until] }])
      SELECT
          distinct conversations.id AS conversation_id,
          conversations.display_id AS conversation_display_id,
          CONCAT('https://chat.bitespeed.co/app/accounts/', conversations.account_id, '/conversations/', conversations.display_id) AS conversation_link,
          conversations.created_at AS conversation_created_at,
          conversations.updated_at AS conversation_updated_at,
          contacts.created_at AS customer_created_at,
          inboxes.name AS inbox_name,
          REPLACE(contacts.phone_number, '+', '') AS customer_phone_number,
          contacts.name AS customer_name,
          COALESCE(users.name, 'None') AS agent_name,
          CASE
            WHEN conversations.status = 0 THEN 'open'
            WHEN conversations.status = 1 THEN 'resolved'
            WHEN conversations.status = 2 THEN 'pending'
            WHEN conversations.status = 3 THEN 'snoozed'
          END AS conversation_status,
          CASE
            WHEN conversations.priority = 0 THEN 'none'
            WHEN conversations.priority = 1 THEN 'low'
            WHEN conversations.priority = 2 THEN 'medium'
            WHEN conversations.priority = 3 THEN 'high'
            WHEN conversations.priority = 4 THEN 'urgent'
            ELSE 'none'
          END AS conversation_priority,
          reporting_events_first_response.value / 60.0 AS first_response_time_minutes,
          latest_conversation_resolved.value / 60.0 AS resolution_time_minutes,
          latest_conversation_resolved.created_at AS resolution_date,
          CASE#{' '}
            WHEN latest_conversation_resolved.created_at IS NOT NULL#{' '}
            THEN EXTRACT(EPOCH FROM (latest_conversation_resolved.created_at - conversations.created_at)) / 86400.0
            ELSE NULL#{' '}
          END AS days_to_resolve,
          conversations.cached_label_list AS labels,
          first_message_after_assignment.first_response_time_after_assignment_minutes
      FROM
          conversations
          JOIN inboxes ON conversations.inbox_id = inboxes.id
          JOIN contacts ON conversations.contact_id = contacts.id
          LEFT JOIN account_users ON conversations.assignee_id = account_users.user_id
          LEFT JOIN users ON account_users.user_id = users.id
          LEFT JOIN reporting_events AS reporting_events_first_response
              ON conversations.id = reporting_events_first_response.conversation_id
              AND reporting_events_first_response.name = 'first_response'
          LEFT JOIN LATERAL (
              SELECT value, created_at
              FROM reporting_events AS re
              WHERE re.conversation_id = conversations.id
              AND re.name = 'conversation_resolved'
              ORDER BY re.created_at DESC
              LIMIT 1
          ) AS latest_conversation_resolved ON true
          LEFT JOIN LATERAL (
              SELECT ca.created_at AS assignment_time
              FROM conversation_assignments ca
              JOIN users u ON ca.assignee_id = u.id
              WHERE ca.conversation_id = conversations.id
                AND (
                  (u.email IS NULL OR u.email NOT LIKE '%@bitespeed.co')
                  AND (u.name IS NULL OR u.name != 'BiteSpeed Bot')
                )
              ORDER BY ca.created_at ASC
              LIMIT 1
          ) AS first_non_bot_assignment ON true
          LEFT JOIN LATERAL (
              SELECT
                  EXTRACT(EPOCH FROM (
                      MIN(m.created_at) - first_non_bot_assignment.assignment_time
                  )) / 60.0 AS first_response_time_after_assignment_minutes
              FROM messages m
              JOIN users u ON m.sender_id = u.id
              WHERE m.conversation_id = conversations.id
                AND m.sender_type = 'User'
                AND m.created_at > first_non_bot_assignment.assignment_time
                AND (
                  (u.email IS NULL OR u.email NOT LIKE '%@bitespeed.co')
                  AND (u.name IS NULL OR u.name != 'BiteSpeed Bot')
                )
          ) AS first_message_after_assignment ON true
      WHERE
          conversations.account_id = :account_id
          AND #{created_at_flag ? 'conversations.created_at' : 'conversations.updated_at'} BETWEEN :since AND :until
    SQL

    result = ActiveRecord::Base.connection.exec_query(sql).to_a
    Rails.logger.info "Report generated for account_id: #{account_id} - #{result.length} records found"
    result
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/BlockLength
  # rubocop:disable Metrics/MethodLength
  def generate_csv(results, start_date, end_date, mask_data)
    CSV.generate(headers: true) do |csv|
      csv << ["Reporting period #{start_date} to #{end_date}"]
      headers = [
        'Conversation ID', 'Conversation Link', 'Conversation Created At', 'Conversation Updated At', 'Contact Created At', 'Inbox Name'
      ]

      # Only include customer details in headers if not masking data
      headers += ['Customer Phone Number', 'Customer Name'] unless mask_data

      headers += ['Agent Name', 'Conversation Status', 'Conversation Priority', 'First Response Time (minutes)', 'Resolution Time (minutes)',
                  'Resolution Date', 'Days to Resolve', 'Labels',
                  'First Response Time After Assignment (minutes)']

      csv << headers
      results.each do |row|
        values = [
          row['conversation_display_id'],
          row['conversation_link'],
          row['conversation_created_at'],
          row['conversation_updated_at'],
          row['customer_created_at'],
          row['inbox_name']
        ]

        # Only include customer details in values if not masking data
        values += [row['customer_phone_number'], row['customer_name']] unless mask_data

        values += [
          row['agent_name'],
          row['conversation_status'],
          row['conversation_priority'],
          row['first_response_time_minutes'],
          row['resolution_time_minutes'],
          row['resolution_date'],
          row['days_to_resolve'],
          row['labels'],
          row['first_response_time_after_assignment_minutes']
        ]

        csv << values
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/BlockLength

  def upload_csv(account_id, range, csv_content, frequency, bitespeed_bot)
    Rails.logger.info "Starting CSV upload for account_id: #{account_id}, frequency: #{frequency}"

    start_date = range[:since].strftime('%Y-%m-%d')
    end_date = range[:until].strftime('%Y-%m-%d')

    # Determine the file name based on the frequency
    file_name = "#{frequency}_conversation_report_#{account_id}_#{end_date}.csv"
    Rails.logger.info "File name: #{file_name}"

    # For testing locally, uncomment below
    # puts csv_content
    # csv_url = file_name
    # File.write(csv_url, csv_content)

    csv_url = upload_to_storage(account_id, file_name, csv_content)
    send_email_notification(account_id, csv_url, start_date, end_date, frequency, bitespeed_bot)

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

  # rubocop:disable Metrics/ParameterLists
  def send_email_notification(account_id, csv_url, start_date, end_date, frequency, bitespeed_bot)
    Rails.logger.info "Sending email notification for account_id: #{account_id}"
    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: Account.find(account_id))

    case frequency
    when 'weekly'
      Rails.logger.info "Sending weekly report email for account_id: #{account_id}"
      mailer.weekly_conversation_report(csv_url, start_date, end_date).deliver_now
    when 'daily'
      Rails.logger.info "Sending daily report email for account_id: #{account_id}"
      mailer.daily_conversation_report(csv_url, end_date).deliver_now
    else
      Rails.logger.info "Sending custom report email for account_id: #{account_id}"
      mailer.custom_conversation_report(csv_url, start_date, end_date, bitespeed_bot).deliver_now
    end
  end
  # rubocop:enable Metrics/ParameterLists
end
# rubocop:enable Metrics/ClassLength
