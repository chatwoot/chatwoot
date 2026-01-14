require 'json'
require 'csv'

# Job to generate and email daily brand summary reports
# Generates three reports: Agents Overview, Agent Conversation States, and Inboxes Overview
class DailyBrandSummaryReportsJob < ApplicationJob # rubocop:disable Metrics/ClassLength
  queue_as :scheduled_jobs

  ACCOUNT_CONFIGS = [
    {
      account_id: 760, # Change this to your actual account ID
      recipient_emails: [
        'jay@procedure.tech' # Change to actual recipient emails
      ],
      business_hours: false
    }
  ].freeze

  def perform
    Rails.logger.info "Starting DailyBrandSummaryReportsJob at #{Time.current}"
    set_statement_timeout

    ACCOUNT_CONFIGS.each do |config|
      process_account(config)
    end

    Rails.logger.info "Completed DailyBrandSummaryReportsJob at #{Time.current}"
  end

  private

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '180s'")
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def process_account(config)
    account_id = config[:account_id]
    recipient_emails = config[:recipient_emails]
    business_hours = config[:business_hours] || false

    Rails.logger.info "Processing daily brand summary reports for account_id: #{account_id}"

    account = Account.find(account_id)

    # Date range: previous day
    range = {
      since: 1.day.ago.beginning_of_day,
      until: 1.day.ago.end_of_day
    }

    report_date = 1.day.ago.strftime('%Y-%m-%d')

    # Build params for reports
    params = {
      since: range[:since],
      until: range[:until],
      business_hours: business_hours
    }

    # Generate all three reports
    csv_urls = {}

    begin
      csv_urls[:agents_overview] = generate_agents_overview_report(account, params, range, report_date)
    rescue StandardError => e
      Rails.logger.error "Failed to generate agents overview report for account #{account_id}: #{e.message}"
    end

    begin
      csv_urls[:agent_conversation_states] = generate_agent_conversation_states_report(account, params, range, report_date)
    rescue StandardError => e
      Rails.logger.error "Failed to generate agent conversation states report for account #{account_id}: #{e.message}"
    end

    begin
      csv_urls[:inboxes_overview] = generate_inboxes_overview_report(account, params, range, report_date)
    rescue StandardError => e
      Rails.logger.error "Failed to generate inboxes overview report for account #{account_id}: #{e.message}"
    end

    # Remove nil values
    csv_urls.compact!

    # Send email if at least one report was generated
    if csv_urls.any?
      send_combined_email(account, csv_urls, report_date, recipient_emails)
      Rails.logger.info "Email sent successfully for account_id: #{account_id}"
    else
      Rails.logger.warn "No reports generated for account_id: #{account_id}, skipping email"
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def generate_agents_overview_report(account, params, _range, report_date)
    Rails.logger.info "Generating agents overview report for account: #{account.id}"

    builder_params = {
      metrics: %w[resolved avg_first_response_time avg_resolution_time avg_response_time
                  median_first_response_time median_resolution_time median_response_time
                  median_csat_score total_online_time],
      group_by: 'agent',
      filters: {
        time_period: {
          type: 'custom',
          start_date: params[:since].to_i,
          end_date: params[:until].to_i
        },
        business_hours: params[:business_hours]
      }
    }

    builder = V2::CustomReportBuilder.new(account, builder_params)
    result = builder.fetch_data

    # Transform to CSV
    csv_content = generate_agents_overview_csv(account, result[:data][:grouped_data], report_date)

    # Upload to storage
    file_name = "daily_agents_overview_#{account.id}_#{report_date}.csv"
    upload_to_storage(account.id, file_name, csv_content)
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def generate_agent_conversation_states_report(account, params, _range, report_date)
    Rails.logger.info "Generating agent conversation states report for account: #{account.id}"

    builder_params = {
      metrics: %w[handled new_assigned open reopened carry_forwarded
                  waiting_customer_response waiting_agent_response resolved
                  resolved_in_pre_time_range resolved_in_time_range snoozed],
      group_by: 'agent',
      filters: {
        time_period: {
          type: 'custom',
          start_date: params[:since].to_i,
          end_date: params[:until].to_i
        },
        business_hours: params[:business_hours]
      }
    }

    builder = V2::CustomReportBuilder.new(account, builder_params)
    result = builder.fetch_data

    # Transform to CSV
    csv_content = generate_agent_conversation_states_csv(account, result[:data][:grouped_data], report_date)

    # Upload to storage
    file_name = "daily_agent_conversation_states_#{account.id}_#{report_date}.csv"
    upload_to_storage(account.id, file_name, csv_content)
  end
  # rubocop:enable Metrics/MethodLength

  def generate_inboxes_overview_report(account, params, _range, report_date)
    Rails.logger.info "Generating inboxes overview report for account: #{account.id}"

    # Set Current.account for the builder (it uses Current.account internally)
    Current.account = account

    builder_params = {
      since: params[:since],
      until: params[:until],
      business_hours: params[:business_hours]
    }

    builder = V2::Reports::InboxSummaryBuilder.new(account: account, params: builder_params)
    report_data = builder.build

    # Transform to CSV
    csv_content = generate_inboxes_overview_csv(account, report_data, report_date)

    # Upload to storage
    file_name = "daily_inboxes_overview_#{account.id}_#{report_date}.csv"
    upload_to_storage(account.id, file_name, csv_content)
  end

  # rubocop:disable Metrics/MethodLength
  def generate_agents_overview_csv(account, grouped_data, report_date) # rubocop:disable Metrics/AbcSize
    CSV.generate(headers: true) do |csv|
      csv << ["All Agents Overview - Reporting period #{report_date}"]
      csv << []

      # Headers
      csv << [
        'Agent Name',
        'Resolved',
        'Avg First Response Time',
        'Avg Resolution Time',
        'Avg Response Time',
        'Median First Response Time',
        'Median Resolution Time',
        'Median Response Time',
        'Median CSAT Score',
        'Total Online Time'
      ]

      # Data rows
      account.users.each do |user|
        agent_data = grouped_data[user.id]
        next unless agent_data

        csv << [
          user.name,
          agent_data['resolved'] || 0,
          format_time(agent_data['avg_first_response_time']),
          format_time(agent_data['avg_resolution_time']),
          format_time(agent_data['avg_response_time']),
          format_time(agent_data['median_first_response_time']),
          format_time(agent_data['median_resolution_time']),
          format_time(agent_data['median_response_time']),
          format_number(agent_data['median_csat_score'], 2),
          format_time(agent_data['total_online_time'])
        ]
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def generate_agent_conversation_states_csv(account, grouped_data, report_date) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    CSV.generate(headers: true) do |csv| # rubocop:disable Metrics/BlockLength
      csv << ["Agent-wise Conversation States - Reporting period #{report_date}"]
      csv << []

      # Headers
      csv << [
        'Agent Name',
        'Handled',
        'New Assigned',
        'Open',
        'Reopened',
        'Carry Forwarded',
        'Waiting Customer',
        'Waiting Agent',
        'Resolved',
        'Resolved (Pre-period)',
        'Resolved (In-period)',
        'Snoozed'
      ]

      # Data rows
      account.users.each do |user|
        agent_data = grouped_data[user.id]
        next unless agent_data

        csv << [
          user.name,
          agent_data['handled'] || 0,
          agent_data['new_assigned'] || 0,
          agent_data['open'] || 0,
          agent_data['reopened'] || 0,
          agent_data['carry_forwarded'] || 0,
          agent_data['waiting_customer_response'] || 0,
          agent_data['waiting_agent_response'] || 0,
          agent_data['resolved'] || 0,
          agent_data['resolved_in_pre_time_range'] || 0,
          agent_data['resolved_in_time_range'] || 0,
          agent_data['snoozed'] || 0
        ]
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def generate_inboxes_overview_csv(account, report_data, report_date)
    CSV.generate(headers: true) do |csv|
      csv << ["All Inboxes Overview - Reporting period #{report_date}"]
      csv << []

      # Headers
      csv << [
        'Inbox Name',
        'Conversations',
        'Resolved Conversations',
        'Avg First Response Time',
        'Avg Resolution Time',
        'Avg Reply Time'
      ]

      # Data rows
      report_data.each do |inbox_data|
        inbox = account.inboxes.find_by(id: inbox_data[:id])
        next unless inbox

        csv << [
          inbox.name,
          inbox_data[:conversations_count] || 0,
          inbox_data[:resolved_conversations_count] || 0,
          format_time(inbox_data[:avg_first_response_time]),
          format_time(inbox_data[:avg_resolution_time]),
          format_time(inbox_data[:avg_reply_time])
        ]
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def format_time(seconds)
    return 'N/A' if seconds.nil? || seconds.zero?

    Reports::TimeFormatPresenter.new(seconds).format
  end

  def format_number(value, precision = 2)
    return 'N/A' if value.nil? || value.zero?

    value.round(precision)
  end

  def upload_to_storage(_account_id, file_name, csv_content)
    Rails.logger.info "Uploading CSV to storage: #{file_name}"

    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(csv_content),
      filename: file_name,
      content_type: 'text/csv'
    )

    csv_url = Rails.application.routes.url_helpers.url_for(blob)
    Rails.logger.info "CSV uploaded successfully: #{csv_url}"
    csv_url
  end

  def send_combined_email(account, csv_urls, report_date, recipient_emails)
    Rails.logger.info "Sending combined email for account: #{account.id}"

    # Set Current.account for the mailer (it uses Current.account internally)
    Current.account = account

    AdministratorNotifications::ChannelNotificationsMailer.with(account: account)
                                                          .daily_brand_summary_reports(
                                                            csv_urls,
                                                            report_date,
                                                            recipient_emails
                                                          ).deliver_now
  end
end
