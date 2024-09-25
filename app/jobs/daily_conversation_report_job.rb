require 'json'
require 'csv'

class DailyConversationReportJob < ApplicationJob
  queue_as :scheduled_jobs

  JOB_DATA_URL = 'https://bitespeed-app.s3.amazonaws.com/InternalAccess/cw-auto-conversation-report.json'.freeze

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def perform
    set_statement_timeout

    # fetching the job data from the URL
    response = HTTParty.get(JOB_DATA_URL)
    job_data = JSON.parse(response.body, symbolize_names: true)

    job_data = job_data[:daily_conversation_report]

    job_data.each do |job|
      current_date = Date.current
      current_day = current_date.wday

      # should trigger only on 1st day of the month
      next if job[:frequency] == 'monthly' && current_date.day != 1

      # should trigger only on Mondays
      next if job[:frequency] == 'weekly' && current_day != 1

      range = if job[:frequency] == 'monthly'
                { since: 1.month.ago.beginning_of_day, until: 1.day.ago.end_of_day }
              elsif job[:frequency] == 'weekly'
                { since: 1.week.ago.beginning_of_day, until: 1.day.ago.end_of_day }
              else
                { since: 1.day.ago.beginning_of_day, until: 1.day.ago.end_of_day }
              end

      process_account(job[:account_id], current_date, range, false, job[:frequency])
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def generate_custom_report(account_id, range, bitespeed_bot)
    set_statement_timeout

    current_date = Date.current

    process_account(account_id, current_date, range, bitespeed_bot, 'custom')
  end

  private

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '60s'")
  end

  def process_account(account_id, _current_date, range, bitespeed_bot, frequency = 'daily')
    report = generate_report(account_id, range)

    if report.present?
      Rails.logger.info "Data found for account_id: #{account_id}"

      start_date = range[:since].strftime('%Y-%m-%d')
      end_date = range[:until].strftime('%Y-%m-%d')

      csv_content = generate_csv(report, start_date, end_date)
      upload_csv(account_id, range, csv_content, frequency, bitespeed_bot)
    else
      Rails.logger.info "No data found for account_id: #{account_id}"
    end
  end

  # rubocop:disable Metrics/MethodLength
  def generate_report(account_id, range)
    # Using ActiveRecord::Base directly for sanitization
    sql = ActiveRecord::Base.send(:sanitize_sql_array, [<<-SQL.squish, { account_id: account_id, since: range[:since], until: range[:until] }])
      SELECT
          distinct conversations.id AS conversation_id,
          conversations.display_id AS conversation_display_id,
          CONCAT('https://chat.bitespeed.co/app/accounts/', conversations.account_id, '/conversations/', conversations.display_id) AS conversation_link,
          conversations.created_at AS conversation_created_at,
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
          reporting_events_first_response.value / 60.0 AS first_response_time_minutes,
          latest_conversation_resolved.value / 60.0 AS resolution_time_minutes,
          conversations.cached_label_list AS labels
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
              SELECT value
              FROM reporting_events AS re
              WHERE re.conversation_id = conversations.id
              AND re.name = 'conversation_resolved'
              ORDER BY re.created_at DESC
              LIMIT 1
          ) AS latest_conversation_resolved ON true
      WHERE
          conversations.account_id = :account_id
          AND conversations.updated_at BETWEEN :since AND :until
    SQL

    ActiveRecord::Base.connection.exec_query(sql).to_a
  end
  # rubocop:enable Metrics/MethodLength

  def generate_csv(results, start_date, end_date)
    CSV.generate(headers: true) do |csv|
      csv << ["Reporting period #{start_date} to #{end_date}"]
      csv << [
        'Conversation ID', 'Conversation Link', 'Conversation Created At', 'Contact Created At', 'Inbox Name',
        'Customer Phone Number', 'Customer Name', 'Agent Name', 'Conversation Status',
        'First Response Time (minutes)', 'Resolution Time (minutes)', 'Labels'
      ]
      results.each do |row|
        csv << [
          row['conversation_display_id'], row['conversation_link'], row['conversation_created_at'], row['customer_created_at'], row['inbox_name'],
          row['customer_phone_number'], row['customer_name'], row['agent_name'], row['conversation_status'],
          row['first_response_time_minutes'], row['resolution_time_minutes'], row['labels']
        ]
      end
    end
  end

  def upload_csv(account_id, range, csv_content, frequency, bitespeed_bot)
    start_date = range[:since].strftime('%Y-%m-%d')
    end_date = range[:until].strftime('%Y-%m-%d')

    # Determine the file name based on the frequency
    file_name = "#{frequency}_conversation_report_#{account_id}_#{end_date}.csv"

    # For testing locally, uncomment below
    # puts csv_content
    # csv_url = file_name
    # File.write(csv_url, csv_content)

    # Upload csv_content via ActiveStorage and print the URL
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(csv_content),
      filename: file_name,
      content_type: 'text/csv'
    )

    csv_url = Rails.application.routes.url_helpers.url_for(blob)

    # Send email with the CSV URL
    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: Account.find(account_id))

    if frequency == 'weekly'
      mailer.weekly_conversation_report(csv_url, start_date, end_date).deliver_now
    elsif frequency == 'daily'
      mailer.daily_conversation_report(csv_url, end_date).deliver_now
    else
      mailer.custom_conversation_report(csv_url, start_date, end_date, bitespeed_bot).deliver_now
    end
  end
end
