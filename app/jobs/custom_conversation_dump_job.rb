# rubocop:disable Metrics/MethodLength

require 'json'
require 'csv'

class CustomConversationDumpJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    set_statement_timeout

    account = Account.find_by(id: 1058)
    # emails = ['jaideep@bitespeed.co']
    emails = ['jaideep@bitespeed.co', 'diksha@bombayshavingcompany.com', 'charu@bombayshavingcompany.com', 'naman@bombayshavingcompany.com']

    # Generate the website unresolved conversations report
    report_data = generate_website_unresolved_report(account)

    if report_data.present?
      Rails.logger.info "CUSTOM_REPORT_JOB: Data found for account_id: #{account.id}"

      emails.each do |email|
        send_website_unresolved_report(account, report_data, email)
      end
    else
      Rails.logger.info "No data found for account_id: #{account.id}"
    end
  end

  private

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '180s'")
  end

  def generate_website_unresolved_report(account)
    sql = <<-SQL.squish
      SELECT c.display_id,
             CONCAT('https://chat.bitespeed.co/app/accounts/', :account_id, '/conversations/', c.display_id) AS conversation_link,
             CASE
                 WHEN m.sender_type IS NULL OR m.sender_id = 3933 THEN 'Bot'
                 WHEN m.sender_type = 'User' THEN 'Agent'
                 ELSE m.sender_type
             END AS sender_type,
             m.content,
             TO_CHAR(m.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Kolkata', 'YYYY-MM-DD HH24:MI:SS') AS created_at_ist
      FROM conversations c
      JOIN messages m ON m.conversation_id = c.id
      WHERE c.account_id = :account_id
        AND c.cached_label_list ILIKE '%website_unresolved%'
        AND m.private = false
        AND m.created_at > NOW() - INTERVAL '1 Day'
        AND m.message_type != 2
      ORDER BY c.id, m.created_at
    SQL

    Rails.logger.info "CUSTOM_REPORT_JOB: Executing website unresolved query for account_id: #{account.id}"

    ActiveRecord::Base.connection.exec_query(
      sql.gsub(':account_id', account.id.to_s)
    ).to_a
  end

  def send_website_unresolved_report(account, report_data, email)
    csv_content = generate_website_unresolved_csv(report_data)
    file_name = "website_unresolved_conversations_#{account.id}_#{Date.current.strftime('%Y-%m-%d')}.csv"

    csv_url = upload_csv(csv_content, file_name)

    subject = "Website Unresolved Conversations Report | #{account.name.capitalize} | #{Date.current.strftime('%Y-%m-%d')}"

    body_html = <<~HTML
      <p>Hello,</p>

      <p>Please find attached the website unresolved conversations report for the last 24 hours.</p>

      <p>
      Click <a href="#{csv_url}">here</a> to download the report.
      </p>

      <p>Regards,<br>BiteSpeed</p>
    HTML

    send_email_via_bspd(subject, email, body_html)
  end

  def generate_website_unresolved_csv(results)
    CSV.generate(headers: true) do |csv|
      csv << [
        'Conversation ID',
        'Conversation Link',
        'Sender Type',
        'Message Content',
        'Created At (IST)'
      ]

      results.each do |row|
        csv << [
          row['display_id'],
          row['conversation_link'],
          row['sender_type'],
          row['content'],
          row['created_at_ist']
        ]
      end
    end
  end

  def upload_csv(csv_content, file_name)
    # For testing locally, uncomment below
    # puts csv_content
    # csv_url = file_name
    # File.write(csv_url, csv_content)

    # Upload csv_content via ActiveStorage and return the URL
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(csv_content),
      filename: file_name,
      content_type: 'text/csv'
    )

    Rails.application.routes.url_helpers.url_for(blob)
  end

  def send_email_via_bspd(subject, to_email, body_html)
    response = HTTParty.post(
      'https://jpk3lbd9jb.execute-api.us-east-1.amazonaws.com/development/sendMail',
      body: {
        subject: subject,
        from: 'support@bitespeed.co',
        to: to_email,
        bodyHtml: body_html
      }.to_json,
      headers: {
        'Content-Type' => 'application/json'
      }
    )

    if response.success?
      Rails.logger.info "Email sent successfully to #{to_email}"
    else
      Rails.logger.error "Failed to send email: #{response.code} - #{response.body}"
    end

    response
  rescue HTTParty::Error => e
    Rails.logger.error "HTTParty error while sending email: #{e.message}"
    raise
  rescue StandardError => e
    Rails.logger.error "Unexpected error while sending email: #{e.message}"
    raise
  end
end
# rubocop:enable Metrics/MethodLength
