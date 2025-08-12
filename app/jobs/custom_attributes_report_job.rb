require 'json'
require 'csv'

# rubocop:disable Metrics/ClassLength
class CustomAttributesReportJob < ApplicationJob
  queue_as :scheduled_jobs

  JOB_DATA_URL = 'https://bitespeed-app.s3.us-east-1.amazonaws.com/InternalAccess/cw-auto-conversation-report.json'.freeze

  def perform
    Rails.logger.info "Starting CustomAttributesReportJob at #{Time.current}"
    set_statement_timeout

    # fetching the job data from the URL
    Rails.logger.info "Fetching job data from URL: #{JOB_DATA_URL}"
    response = HTTParty.get(JOB_DATA_URL)
    job_data = JSON.parse(response.body, symbolize_names: true)

    job_data = job_data[:custom_attributes_report]
    Rails.logger.info "Found #{job_data.length} jobs to process"

    job_data.each do |job|
      process_job(job)
    end

    Rails.logger.info "Completed CustomAttributesReportJob at #{Time.current}"
  end

  def generate_custom_report(account_id, range, bitespeed_bot)
    Rails.logger.info "Starting custom attributes report generation for account_id: #{account_id}"
    set_statement_timeout

    current_date = Date.current

    process_account(account_id, current_date, range, bitespeed_bot, 'custom', false)
    Rails.logger.info "Completed custom attributes report generation for account_id: #{account_id}"
  end

  private

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  def process_job(job)
    Rails.logger.info "Processing custom attributes job for account_id: #{job[:account_id]}, frequency: #{job[:frequency]}"

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
    Rails.logger.info "Starting to process custom attributes for account_id: #{account_id} with frequency: #{frequency}"

    report = generate_report(account_id, range, created_at_flag: created_at_flag)

    if report.present?
      Rails.logger.info "Data found for account_id: #{account_id} - #{report.length} records"

      start_date = range[:since].strftime('%Y-%m-%d')
      end_date = range[:until].strftime('%Y-%m-%d')

      Rails.logger.info "Generating CSV for account_id: #{account_id}"
      csv_content = generate_csv(report, start_date, end_date, mask_data, account_id)
      Rails.logger.info "CSV generated for account_id: #{account_id} - #{csv_content.bytesize} bytes"

      upload_csv(account_id, range, csv_content, frequency, bitespeed_bot)
    else
      Rails.logger.info "No data found for account_id: #{account_id}"
    end
  end
  # rubocop:enable Metrics/ParameterLists

  # rubocop:disable Metrics/MethodLength
  def generate_report(account_id, range, created_at_flag: false)
    Rails.logger.info "Generating custom attributes report for account_id: #{account_id} with range: #{range[:since]} to #{range[:until]}"

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
          conversations.cached_label_list AS labels,
          conversations.custom_attributes AS custom_attributes
      FROM
          conversations
          JOIN inboxes ON conversations.inbox_id = inboxes.id
          JOIN contacts ON conversations.contact_id = contacts.id
          LEFT JOIN account_users ON conversations.assignee_id = account_users.user_id
          LEFT JOIN users ON account_users.user_id = users.id
      WHERE
          conversations.account_id = :account_id
          AND #{created_at_flag ? 'conversations.created_at' : 'conversations.updated_at'} BETWEEN :since AND :until
    SQL

    result = ActiveRecord::Base.connection.exec_query(sql).to_a
    Rails.logger.info "Custom attributes report generated for account_id: #{account_id} - #{result.length} records found"
    result
  end

  def generate_csv(results, start_date, end_date, mask_data, account_id) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
    # Get custom attributes that are required before resolve for this account
    required_custom_attributes = CustomAttributeDefinition.where(
      account_id: account_id,
      attribute_model: 'conversation_attribute',
      required_before_resolve: true
    ).order(:attribute_display_name)

    Rails.logger.info "Found #{required_custom_attributes.length} required custom attributes for account_id: #{account_id}"

    CSV.generate(headers: true) do |csv|
      csv << ["Custom Attributes Report - Reporting period #{start_date} to #{end_date}"]

      # Base headers
      headers = [
        'Conversation ID', 'Conversation Link', 'Conversation Created At', 'Conversation Updated At',
        'Contact Created At', 'Inbox Name', 'Labels', 'Agent Name'
      ]

      # Only include customer details in headers if not masking data
      headers += ['Customer Phone Number', 'Customer Name'] unless mask_data

      # Add custom attribute headers
      required_custom_attributes.each do |attr|
        headers << attr.attribute_display_name
      end

      csv << headers

      results.each do |row|
        # Parse custom attributes JSON
        custom_attrs = row['custom_attributes'].present? ? JSON.parse(row['custom_attributes']) : {}

        # Base values
        values = [
          row['conversation_display_id'],
          row['conversation_link'],
          row['conversation_created_at'],
          row['conversation_updated_at'],
          row['customer_created_at'],
          row['inbox_name'],
          row['labels'],
          row['agent_name']
        ]

        # Only include customer details in values if not masking data
        values += [row['customer_phone_number'], row['customer_name']] unless mask_data

        # Add custom attribute values
        required_custom_attributes.each do |attr|
          attribute_value = custom_attrs[attr.attribute_key]
          values << (attribute_value.present? ? attribute_value.to_s : '')
        end

        csv << values
      end
    end
  end

  # rubocop:enable Metrics/MethodLength
  def upload_csv(account_id, range, csv_content, frequency, bitespeed_bot)
    Rails.logger.info "Starting CSV upload for account_id: #{account_id}, frequency: #{frequency}"

    start_date = range[:since].strftime('%Y-%m-%d')
    end_date = range[:until].strftime('%Y-%m-%d')

    # Determine the file name based on the frequency
    file_name = "#{frequency}_custom_attributes_report_#{account_id}_#{end_date}.csv"
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
      Rails.logger.info "Sending weekly custom attributes report email for account_id: #{account_id}"
      mailer.weekly_custom_attributes_report(csv_url, start_date, end_date).deliver_now
    when 'daily'
      Rails.logger.info "Sending daily custom attributes report email for account_id: #{account_id}"
      mailer.daily_custom_attributes_report(csv_url, end_date).deliver_now
    else
      Rails.logger.info "Sending custom attributes report email for account_id: #{account_id}"
      mailer.custom_attributes_report(csv_url, start_date, end_date, bitespeed_bot).deliver_now
    end
  end
  # rubocop:enable Metrics/ParameterLists
end
# rubocop:enable Metrics/ClassLength
