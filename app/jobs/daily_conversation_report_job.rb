require 'json'
require 'csv'

class DailyConversationReportJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    job_data = [{
      account_id: 138,
      frequency: 'daily'
    }, {
      account_id: 138,
      frequency: 'weekly' # should trigger only on Mondays
    },
                {
                  account_id: 504,
                  frequency: 'daily'
                }]

    job_data.each do |job|
      current_date = Date.current
      current_day = current_date.wday

      next if job[:frequency] == 'weekly' && current_day != 0

      current_date = Date.current

      process_account(job[:account_id], current_date, job[:frequency])
    end
  end

  private

  def process_account(account_id, current_date, frequency)
    report = generate_report(account_id, frequency)

    if report.present?
      Rails.logger.info "Data found for account_id: #{account_id}"

      csv_content = generate_csv(report)
      upload_csv(account_id, current_date, csv_content, frequency)
    else
      Rails.logger.info "No data found for account_id: #{account_id}"
    end
  end

  # rubocop:disable Metrics/MethodLength
  def generate_report(account_id, frequency = 'daily')
    range = if frequency == 'weekly'
              { since: 1.week.ago, until: Time.current }
            else
              { since: 1.day.ago, until: Time.current }
            end

    # Using ActiveRecord::Base directly for sanitization
    sql = ActiveRecord::Base.send(:sanitize_sql_array, [<<-SQL.squish, { account_id: account_id, since: range[:since], until: range[:until] }])
      SELECT
          conversations.id AS conversation_id,
          conversations.display_id AS conversation_display_id,
          conversations.created_at AS conversation_created_at,
          contacts.created_at AS customer_created_at,
          inboxes.name AS inbox_name,
          REPLACE(contacts.phone_number, '+', '') AS customer_phone_number,
          contacts.name AS customer_name,
          users.name AS agent_name,
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
          JOIN account_users ON conversations.assignee_id = account_users.user_id
          JOIN users ON account_users.user_id = users.id
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

  def generate_csv(results)
    CSV.generate(headers: true) do |csv|
      csv << [
        'Conversation ID', 'Conversation Created At', 'Contact Created At', 'Inbox Name',
        'Customer Phone Number', 'Customer Name', 'Agent Name', 'Conversation Status',
        'First Response Time (minutes)', 'Resolution Time (minutes)', 'Labels'
      ]
      results.each do |row|
        csv << [
          row['conversation_display_id'], row['conversation_created_at'], row['customer_created_at'], row['inbox_name'],
          row['customer_phone_number'], row['customer_name'], row['agent_name'], row['conversation_status'],
          row['first_response_time_minutes'], row['resolution_time_minutes'], row['labels']
        ]
      end
    end
  end

  def upload_csv(account_id, current_date, csv_content, frequency)
    # Determine the file name based on the frequency
    file_name = "#{frequency}_conversation_report_#{account_id}_#{current_date}.csv"

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
      mailer.weekly_conversation_report(csv_url, current_date - 7.days, current_date).deliver_now
    else
      mailer.daily_conversation_report(csv_url, current_date).deliver_now
    end
  end
end
