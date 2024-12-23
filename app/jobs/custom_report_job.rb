# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity

require 'json'
require 'csv'

class CustomReportJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(account, input, email)
    set_statement_timeout

    report = build_report(account, input)

    Rails.logger.info "CUSTOM_REPORT_JOB: perform: report: #{report}"

    process_report(account, report, input[:metrics], email)
  end

  private

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '60s'")
  end

  def build_report(account, input)
    Rails.logger.info "CUSTOM_REPORT_JOB: build_report: input: #{input}"
    V2::CustomReportBuilder.new(account, input).fetch_data
  end

  def process_report(account, report, metrics, email)
    if report[:data][:grouped_data].present?
      readable_report = generate_readable_report(account, report[:data][:grouped_data], report[:data][:grouped_data][:grouped_by])

      if readable_report.present?
        mail_csv(account, readable_report, metrics, report, email)
      else
        Rails.logger.info "No data found for account_id: #{account.id}"
      end
    else
      Rails.logger.info 'No emails for non grouped data'
    end
  end

  def generate_readable_report(account, grouped_data, grouped_by)
    case grouped_by
    when 'agent'
      generate_agent_report(account, grouped_data)
    when 'inbox'
      generate_inbox_report(account, grouped_data)
    when 'working_hours'
      generate_working_hours_report(grouped_data)
    end
  end

  def generate_agent_report(account, grouped_data)
    account.users.map do |agent|
      [agent.name] + generate_readable_report_metrics(grouped_data[agent.id])
    end
  end

  def generate_inbox_report(grouped_data)
    account.inboxes.map do |inbox|
      [inbox.name] + generate_readable_report_metrics(grouped_data[inbox.id])
    end
  end

  def generate_working_hours_report(grouped_data)
    Rails.logger.info "CUSTOM_REPORT_JOB: generate_working_hours_report: grouped_data: #{grouped_data}"
    # Remove grouped_by from the data since we don't need it in the report
    data = grouped_data.except('grouped_by', :grouped_by)

    # Define time-based metrics
    time_based_metric_keys = %w[conversations_count avg_first_response_time avg_resolution_time avg_response_time
                                median_first_response_time median_resolution_time median_response_time bot_avg_resolution_time]

    # For each metric, create rows with working_hours and non_working_hours values
    rows = %w[working_hours non_working_hours].map do |period|
      row = [period] # Just the period name
      data.each do |metric, values|
        # Add nil checks and default values
        Rails.logger.info "CUSTOM_REPORT_JOB: generate_working_hours_report: metric: #{metric}, values: #{values}, period: #{period}"
        value = if values.nil?
                  metric == 'bot_avg_resolution_time' ? '--' : 0 # Use '--' for time metrics when nil
                elsif values.is_a?(Hash)
                  values[period] || values[period.to_sym] || (metric == 'bot_avg_resolution_time' ? '--' : 0)
                else
                  values
                end

        # Format value if it's a time-based metric and not '--'
        value = Reports::TimeFormatPresenter.new(value).format if time_based_metric_keys.include?(metric) && value != '--'
        Rails.logger.info "CUSTOM_REPORT_JOB: generate_working_hours_report: value: #{value}"
        row << value if value != 'working_hours'
      end
      row
    end

    # Add total row
    total_row = ['total'] # Just the word 'total'
    data.each do |metric, values|
      value = if values.nil?
                metric == 'bot_avg_resolution_time' ? '--' : 0
              elsif values.is_a?(Hash) && values.key?('total')
                values['total']
              else
                # Calculate sum of working_hours and non_working_hours
                # Convert nil to 0 for calculation
                (values.is_a?(Hash) ? values.values : [values]).sum { |v| v || 0 }
              end

      # Format value if it's a time-based metric and not '--'
      value = Reports::TimeFormatPresenter.new(value).format if time_based_metric_keys.include?(metric) && value != '--'
      total_row << value if value != 'working_hours'
    end

    rows + [total_row]
  end

  def generate_readable_report_metrics(report_metrics)
    time_based_metric_keys = %w[conversations_count avg_first_response_time avg_resolution_time avg_response_time median_first_response_time
                                median_resolution_time median_response_time bot_avg_resolution_time]

    report_metrics.keys.map do |key|
      if time_based_metric_keys.include?(key)
        Reports::TimeFormatPresenter.new(report_metrics[key]).format
      else
        report_metrics[key] || 0
      end
    end
  end

  def format_date(date_value)
    case date_value
    when Integer
      Time.at(date_value).utc.to_date.strftime('%Y-%m-%d')
    when Time
      date_value.to_date.strftime('%Y-%m-%d')
    when String
      Date.parse(date_value).strftime('%Y-%m-%d')
    else
      raise ArgumentError, "Unsupported date format: #{date_value.class}"
    end
  rescue ArgumentError => e
    Rails.logger.error("Error parsing date: #{e.message}")
    'Unknown Date'
  end

  def mail_csv(account, readable_report, metrics, report, email)
    start_date = format_date(report[:time_range][:start_date])
    end_date = format_date(report[:time_range][:end_date])
    grouped_by = report[:data][:grouped_data][:grouped_by]

    grouped_by = 'Period' if grouped_by == 'working_hours'

    csv_content = generate_csv(readable_report, grouped_by, metrics, start_date, end_date)

    file_name = "#{grouped_by}_report_#{account.id}_#{start_date}_#{end_date}.csv"

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
    subject = "#{grouped_by.capitalize} Report from #{start_date} to #{end_date} | #{account.name.capitalize}"
    body_html = <<~HTML
      <p>Hello,</p>

      <p>Please find attached the report you requested.</p>

      <p>
      Click <a href="#{csv_url}">here</a> to download.
      </p>

      <p>Regards,<br>BiteSpeed</p>
    HTML

    send_email_via_bspd(subject, email, body_html)
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

  def generate_csv(readable_report, grouped_by, metrics, start_date, end_date)
    CSV.generate do |csv|
      csv << ["Reporting period #{start_date} to #{end_date}"]
      csv << []
      headers = ["#{grouped_by.capitalize} name"]
      metrics.each do |metric|
        headers << (metric_titles[metric] || metric.humanize)
      end
      csv << headers

      readable_report.each do |row|
        csv << row
      end
    end
  end

  # :
  def metric_titles
    {
      'conversations_count' => 'Assigned conversations',
      'avg_first_response_time' => 'Avg first response time',
      'avg_resolution_time' => 'Avg resolution time',
      'online_time' => 'Online time',
      'busy_time' => 'Busy time',
      'avg_waiting_time' => 'Avg customer waiting time',
      'open' => 'Open conversations',
      'unattended' => 'Unattended conversations',
      'resolved' => 'Resolution Count',
      'new_assigned' => 'New assigned conversations',
      'reopened' => 'Reopened conversations',
      'carry_forwarded' => 'Carry forwarded conversations',
      'waiting_agent_response' => 'Waiting for agent response',
      'waiting_customer_response' => 'Waiting for customer response',
      'snoozed' => 'Snoozed conversations',
      'avg_response_time' => 'Avg response time',
      'avg_csat_score' => 'Avg CSAT score',
      'median_first_response_time' => 'Median first response time',
      'median_resolution_time' => 'Median resolution time',
      'median_response_time' => 'Median response time',
      'median_csat_score' => 'Median CSAT score',
      'bot_total_revenue' => 'Bot total revenue',
      'sales_ooo_hours' => 'Sales OOO hours',
      'bot_handled' => 'Bot handled conversations',
      'bot_resolved' => 'Bot resolved conversations',
      'bot_avg_resolution_time' => 'Bot avg resolution time',
      'bot_assign_to_agent' => 'Bot assign to agent',
      'pre_sale_queries' => 'Pre sale queries',
      'bot_orders_placed' => 'Bot orders placed',
      'bot_revenue_generated' => 'Bot revenue generated'
    }
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/MethodLength
