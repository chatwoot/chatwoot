require 'json'
require 'csv'

class LabelReportJob < ApplicationJob
  queue_as :scheduled_jobs

  JOB_DATA_URL = 'https://bitespeed-app.s3.us-east-1.amazonaws.com/InternalAccess/cw-auto-conversation-report.json'.freeze

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def perform
    set_statement_timeout

    response = HTTParty.get(JOB_DATA_URL)
    job_data = JSON.parse(response.body, symbolize_names: true)

    job_data = job_data[:label_report]

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

      if job[:type].present? && job[:type] == 'overall'
        process_account_overall_data(job[:account_id], range, false, job[:frequency])
      else
        process_account(job[:account_id], range, false, job[:frequency])
      end
    end
  end

  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '60s'")
  end

  def working_hours_enabled?(account_id)
    Account.find(account_id).inboxes.any?(&:working_hours_enabled?)
  end

  def process_account_overall_data(account_id, range, bitespeed_bot, frequency = 'daily')
    report = generate_label_report_overall(account_id, range)

    if report.present?
      Rails.logger.info "Data found for account_id: #{account_id}"

      start_date = range[:since].strftime('%Y-%m-%d')
      end_date = range[:until].strftime('%Y-%m-%d')

      csv_content = generate_csv_overall(report, start_date, end_date)
      upload_csv(account_id, range, csv_content, frequency, bitespeed_bot)
    else
      Rails.logger.info "No data found for account_id: #{account_id}"
    end
  end

  def process_account(account_id, range, bitespeed_bot, frequency = 'daily')
    agents = AccountUser.includes(:user).where(account_id: account_id)
    reports = []

    agents.each do |agent|
      report = generate_label_report_per_agent(account_id, range, agent)
      reports << report
    end

    if reports.present? && reports.length.positive?
      Rails.logger.info "Data found for account_id: #{account_id}"

      start_date = range[:since].strftime('%Y-%m-%d')
      end_date = range[:until].strftime('%Y-%m-%d')

      csv_content = generate_csv(reports, agents, start_date, end_date)
      upload_csv(account_id, range, csv_content, frequency, bitespeed_bot)
    else
      Rails.logger.info "No data found for account_id: #{account_id}"
    end
  end

  def generate_label_report_per_agent(account_id, range, agent)
    account = Account.find(account_id)
    business_hours = working_hours_enabled?(account_id)
    account.labels.map do |label|
      report = generate_report(account,
                               { type: :label, id: label.id, since: range[:since], until: range[:until], assignee_id: agent.user_id,
                                 business_hours: business_hours })
      [label.title] + generate_readable_report_metrics(report)
    end
  end

  def generate_label_report_overall(account_id, range)
    account = Account.find(account_id)
    account.labels.map do |label|
      report = generate_report(account, { type: :label, id: label.id, since: range[:since], until: range[:until], business_hours: true })
      [label.title] + generate_readable_report_metrics(report)
    end
  end

  def report_builder(account, report_params)
    V2::ReportBuilder.new(
      account,
      report_params
    )
  end

  def generate_report(account, report_params)
    report_builder(account, report_params).custom_short_summary
  end

  def generate_readable_report_metrics(report)
    [
      report[:conversations_count],
      Reports::TimeFormatPresenter.new(report[:avg_first_response_time]).format,
      Reports::TimeFormatPresenter.new(report[:avg_resolution_time]).format,
      report[:open_conversations_count],
      report[:unattended_conversations_count],
      report[:resolved_conversations_count]
    ]
  end

  def generate_csv(results, agents, start_date, end_date)
    CSV.generate(headers: true) do |csv|
      csv << ["Reporting period #{start_date} to #{end_date}"]
      csv << []

      agents.each_with_index do |agent, index|
        csv << ["Agent Name: #{agent.user.name}"]
        csv << ['Label', 'No. of conversations', 'Avg first response time', 'Avg resolution time', 'Open conversations', 'Unattended conversations',
                'Resolved conversations']

        results[index].each do |row|
          csv << row
        end

        csv << []
        csv << []
      end
    end
  end

  def generate_csv_overall(result, start_date, end_date)
    CSV.generate(headers: true) do |csv|
      csv << ["Reporting period #{start_date} to #{end_date}"]
      csv << []
      csv << ['Label', 'No. of conversations', 'Avg first response time', 'Avg resolution time', 'Open conversations', 'Unattended conversations',
              'Resolved conversations']
      result.each do |row|
        csv << row
      end
    end
  end

  def upload_csv(account_id, range, csv_content, frequency, _bitespeed_bot)
    start_date = range[:since].strftime('%Y-%m-%d')
    end_date = range[:until].strftime('%Y-%m-%d')

    # Determine the file name based on the frequency
    file_name = "#{frequency}_label_report_#{account_id}_#{end_date}.csv"

    # For testing locally, uncomment below
    # Rails.logger.debug csv_content
    # csv_url = file_name
    # File.write(csv_url, csv_content)
    # Rails.logger.debug { "CSV URL: #{csv_url}" }

    # Upload csv_content via ActiveStorage and print the URL
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(csv_content),
      filename: file_name,
      content_type: 'text/csv'
    )

    csv_url = Rails.application.routes.url_helpers.url_for(blob)

    # Send email with the CSV URL
    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: Account.find(account_id))

    case frequency
    when 'monthly'
      mailer.monthly_label_report(csv_url, start_date, end_date).deliver_now
    when 'weekly'
      mailer.weekly_label_report(csv_url, start_date, end_date).deliver_now
    when 'daily'
      mailer.daily_label_report(csv_url, end_date).deliver_now
    end
  end
end
