require 'csv'

class MessageReportJob < ApplicationJob
  queue_as :scheduled_jobs

  BRAND_CONFIGS = [
    { account_id: 209, recipient_emails: ['support@layers.shop', 'jay@procedure.tech'] }
  ].freeze

  def perform
    Rails.logger.info "Starting MessageReportJob at #{Time.current}"
    set_statement_timeout

    BRAND_CONFIGS.each do |config|
      process_brand(config)
    end

    Rails.logger.info "MessageReportJob completed successfully at #{Time.current}"
  end

  private

  def process_brand(config)
    account_id = config[:account_id]
    recipient_emails = config[:recipient_emails]

    Rails.logger.info "Processing brand for account_id: #{account_id}"

    report = generate_report(account_id)
    if report.present?
      Rails.logger.info "Found #{report.length} messages for account_id: #{account_id}"

      end_date = Time.current
      start_date = 48.hours.ago

      csv_content = generate_csv(report, start_date, end_date, account_id)
      upload_and_send_email(csv_content, start_date, end_date, account_id, recipient_emails)

      Rails.logger.info "Completed processing for account_id: #{account_id}"
    else
      Rails.logger.info "No messages found for account_id: #{account_id}"
    end
  end

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '120s'")
  end

  def generate_report(account_id) # rubocop:disable Metrics/MethodLength
    Rails.logger.info "Generating message report for account_id: #{account_id}"

    since_time = 48.hours.ago
    sql = ActiveRecord::Base.send(:sanitize_sql_array, [<<-SQL.squish, { account_id: account_id, since: since_time }])
      SELECT
          conversations.display_id as conversation_id,
          messages.content,
          users.name AS agent_name,
          contacts.name AS contact_name,
          contacts.phone_number AS contact_phone,
          contacts.email AS contact_email,
          contacts.additional_attributes->>'social_instagram_user_name' AS contact_instagram,
          messages.created_at as message_timestamp
      FROM messages
      JOIN conversations ON messages.conversation_id = conversations.id
      JOIN inboxes ON conversations.inbox_id = inboxes.id
      LEFT JOIN users ON messages.sender_type = 'User' AND messages.sender_id = users.id
      LEFT JOIN contacts ON messages.sender_type = 'Contact' AND messages.sender_id = contacts.id
      WHERE messages.private = FALSE
          AND messages.message_type != 2
          AND (messages.additional_attributes IS NULL
               OR messages.additional_attributes->>'ignore_automation_rules' IS DISTINCT FROM 'true')
          AND messages.account_id = :account_id
          AND messages.created_at >= :since
      ORDER BY message_timestamp ASC
    SQL

    result = ActiveRecord::Base.connection.exec_query(sql).to_a
    Rails.logger.info "Report generated - #{result.length} records found"
    result
  end

  def generate_csv(results, start_date, end_date, account_id) # rubocop:disable Metrics/MethodLength
    CSV.generate(headers: true) do |csv|
      csv << ["Message Report for Account #{account_id}"]
      csv << ["Period: #{start_date.strftime('%Y-%m-%d %H:%M')} to #{end_date.strftime('%Y-%m-%d %H:%M')}"]
      csv << []

      headers = [
        'Conversation ID',
        'Message Content',
        'Agent Name',
        'Contact Name',
        'Contact Phone',
        'Contact Email',
        'Contact Instagram',
        'Message Timestamp'
      ]

      csv << headers

      results.each do |row|
        csv << [
          row['conversation_id'],
          row['content'],
          row['agent_name'],
          row['contact_name'],
          row['contact_phone'],
          row['contact_email'],
          row['contact_instagram'],
          row['message_timestamp']
        ]
      end
    end
  end

  def upload_and_send_email(csv_content, start_date, end_date, account_id, recipient_emails)
    file_name = "message_report_#{account_id}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"

    Rails.logger.info "Uploading CSV: #{file_name}"

    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(csv_content),
      filename: file_name,
      content_type: 'text/csv'
    )

    csv_url = Rails.application.routes.url_helpers.url_for(blob)
    Rails.logger.info "CSV uploaded successfully, URL: #{csv_url}"

    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: Account.find(account_id))
    mailer.message_report(csv_url, start_date.strftime('%Y-%m-%d'), end_date.strftime('%Y-%m-%d'), recipient_emails).deliver_now

    Rails.logger.info "Email sent to #{recipient_emails.join(', ')}"
  end
end
