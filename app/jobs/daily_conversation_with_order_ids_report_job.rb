require 'uri'
require 'json'
require 'net/http'
require 'csv'

class DailyConversationWithOrderIdsReportJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    account_ids = [579] # enabled for headway
    current_date = Date.current

    account_ids.each do |account_id|
      process_account(account_id, current_date)
    end
  end

  private

  def process_account(account_id, current_date)
    report = generate_report(account_id)

    if report.present?
      Rails.logger.info "Data found for account_id: #{account_id}"

      phone_numbers_and_dates = extract_phone_numbers_and_dates(report)
      order_ids = fetch_order_ids(account_id, phone_numbers_and_dates)

      update_report_with_order_ids(report, order_ids)

      csv_content = generate_csv(report)
      upload_csv(account_id, current_date, csv_content)
    else
      Rails.logger.info "No data found for account_id: #{account_id}"
    end
  end

  # rubocop:disable Metrics/MethodLength
  def generate_report(account_id)
    # Using ActiveRecord::Base directly for sanitization
    sql = ActiveRecord::Base.send(:sanitize_sql_array, [<<-SQL.squish, { account_id: account_id }])
      SELECT DISTINCT ON (conversations.id)
          conversations.id AS conversation_id,
          conversations.display_id AS conversation_display_id,
          CONCAT('https://chat.bitespeed.co/app/accounts/', conversations.account_id, '/conversations/', conversations.display_id) AS conversation_link,
          conversations.created_at AS conversation_created_at,
          contacts.created_at AS customer_created_at,
          inboxes.name AS inbox_name,
          REPLACE(contacts.phone_number, '+', '') AS customer_phone_number,
          contacts.email AS customer_email,
          contacts.additional_attributes->>'social_instagram_user_name' AS customer_instagram,
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
          LEFT JOIN reporting_events AS reporting_events_first_response
              ON conversations.id = reporting_events_first_response.conversation_id
              AND reporting_events_first_response.name = 'first_response'
          LEFT JOIN LATERAL (
              SELECT value, user_id
              FROM reporting_events AS re
              WHERE re.conversation_id = conversations.id
              AND re.name = 'conversation_resolved'
              ORDER BY re.created_at DESC
              LIMIT 1
          ) AS latest_conversation_resolved ON true
          JOIN users ON COALESCE(latest_conversation_resolved.user_id, account_users.user_id) = users.id
      WHERE
          conversations.account_id = :account_id
          AND conversations.updated_at >= ((NOW() AT TIME ZONE 'Asia/Kolkata')::DATE - INTERVAL '1 day 5 hours 30 minutes')
          AND conversations.updated_at < ((NOW() AT TIME ZONE 'Asia/Kolkata')::DATE - INTERVAL '5 hours 30 minutes')
    SQL

    ActiveRecord::Base.connection.exec_query(sql).to_a
  end
  # rubocop:enable Metrics/MethodLength

  def extract_phone_numbers_and_dates(report)
    report
      .reject { |row| row['customer_phone_number'].nil? }
      .map { |row| { phoneNumber: row['customer_phone_number'], createdAt: row['conversation_created_at'] } }
  end

  def fetch_order_ids(account_id, phone_numbers_and_dates)
    # url = URI('http://localhost:3000/previousOrdersByPhoneNumber')
    url = URI('https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/previousOrdersByPhoneNumber')

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'application/json'
    request.body = JSON.dump({
                               'accountId': account_id.to_s,
                               'payload': phone_numbers_and_dates
                             })

    response = http.request(request)
    JSON.parse(response.body)['orders']
  rescue StandardError => e
    Rails.logger.error "Failed to fetch order IDs: #{e.message}"
    []
  end

  def update_report_with_order_ids(report, order_ids)
    report.each do |row|
      matching_order = order_ids.find { |order| order['phoneNumber'] == row['customer_phone_number'] }
      row['order_id'] = matching_order ? matching_order['orderId'] : nil
    end
  end

  def generate_csv(results)
    CSV.generate(headers: true) do |csv|
      csv << [
        'Conversation ID', 'Conversation Link', 'Inbox Name', 'Customer Phone Number', 'Customer Email', 'Customer Instagram',
        'Customer Name', 'Labels', 'Order ID', 'Conversation Created At', 'Contact Created At'
      ]
      results.each do |row|
        csv << [
          row['conversation_display_id'], row['conversation_link'], row['inbox_name'], row['customer_phone_number'], row['customer_email'],
          row['customer_instagram'], row['customer_name'], row['labels'], row['order_id'], row['conversation_created_at'], row['customer_created_at']
        ]
      end
    end
  end

  def upload_csv(account_id, current_date, csv_content)
    # # for testing locally uncomment below
    # puts csv_content
    # csv_url = "daily_conversation_report_#{account_id}_#{current_date}.csv"
    # File.write(csv_url, csv_content)

    # Upload csv_content via ActiveStorage and print the URL
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(csv_content),
      filename: "daily_conversation_report_#{account_id}_#{current_date}.csv",
      content_type: 'text/csv'
    )

    csv_url = Rails.application.routes.url_helpers.url_for(blob)

    # Send email with the CSV URL
    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: Account.find(account_id))
    mailer.daily_conversation_report(csv_url, current_date).deliver_now
  end
end
