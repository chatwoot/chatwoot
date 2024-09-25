require 'json'
require 'csv'

class DailyInboxReportJob < ApplicationJob
  queue_as :scheduled_jobs

  # TODO: [P0] fix why numbers not visible in the report

  # TODO: add new .json file for label wise report
  # JOB_DATA_URL = 'https://bitespeed-app.s3.amazonaws.com/InternalAccess/cw-auto-conversation-report.json'.freeze

  def perform
    set_statement_timeout

    # fetching the job data from the URL
    # response = HTTParty.get(JOB_DATA_URL)
    # job_data = JSON.parse(response.body, symbolize_names: true)
    job_data = [{
      account_id: 785,
      frequency: 'weekly'
    }]

    job_data.each do |job|
      current_date = Date.current
      current_date.wday

      # should trigger only on Mondays
      # next if job[:frequency] == 'weekly' && current_day != 1

      current_date = Date.current

      range = if job[:frequency] == 'weekly'
                { since: 1.week.ago.beginning_of_day, until: 1.day.ago.end_of_day }
              else
                { since: 1.day.ago.beginning_of_day, until: 1.day.ago.end_of_day }
              end

      process_account(job[:account_id], current_date, range, false, job[:frequency])
    end
  end
  # def generate_custom_report(account_id, range, bitespeed_bot)
  #   set_statement_timeout

  #   current_date = Date.current

  #   process_account(account_id, current_date, range, bitespeed_bot, 'custom')
  # end

  private

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '60s'")
  end

  def process_account(account_id, _current_date, range, bitespeed_bot, frequency = 'daily')
    # pass individual label ids to the report builder and join them as one report
    # get all the labels for the account
    labels = Label.where(account_id: account_id)

    Rails.logger.debug { "Labels: #{labels.inspect}" }

    reports = []

    labels.map do |label|
      report = generate_inbox_report(account_id, range, label.title)
      reports << report
    end

    if reports.present? && reports.length.positive?
      Rails.logger.info "Data found for account_id: #{account_id}"

      start_date = range[:since].strftime('%Y-%m-%d')
      end_date = range[:until].strftime('%Y-%m-%d')

      csv_content = generate_csv(reports, labels, start_date, end_date)
      upload_csv(account_id, range, csv_content, frequency, bitespeed_bot)
    else
      Rails.logger.info "No data found for account_id: #{account_id}"
    end
  end

  def generate_inbox_report(account_id, range, label)
    account = Account.find(account_id)
    account.inboxes.map do |inbox|
      inbox_report = generate_report(account, { type: :inbox, id: inbox.id, since: range[:since], until: range[:until], label: label })
      [inbox.name, inbox.channel&.name] + generate_readable_report_metrics(inbox_report)
    end
  end

  def report_builder(account, report_params)
    V2::ReportBuilder.new(
      account,
      report_params
    )
  end

  def generate_report(account, report_params)
    report_builder(account, report_params).short_summary
  end

  def generate_readable_report_metrics(report_metric)
    [
      report_metric[:conversations_count],
      Reports::TimeFormatPresenter.new(report_metric[:avg_first_response_time]).format,
      Reports::TimeFormatPresenter.new(report_metric[:avg_resolution_time]).format,
      Reports::TimeFormatPresenter.new(report_metric[:online_time]).format,
      Reports::TimeFormatPresenter.new(report_metric[:busy_time]).format,
      Reports::TimeFormatPresenter.new(report_metric[:reply_time]).format,
      report_metric[:resolutions_count]
    ]
  end

  def generate_csv(results, labels, start_date, end_date)
    Rails.logger.debug { "Results: #{results}" }
    Rails.logger.debug { "Labels: #{labels}" }
    Rails.logger.debug { "Start date: #{start_date}" }
    Rails.logger.debug { "End date: #{end_date}" }
    CSV.generate(headers: true) do |csv|
      csv << ["Reporting period #{start_date} to #{end_date}"]
      csv << []

      labels.each_with_index do |label, index|
        csv << ["Label: #{label.title}"]
        csv << ['Inbox name', 'Inbox type', 'No. of conversations', 'Avg first response time', 'Avg resolution time']

        results[index].each do |row|
          csv << row
        end

        csv << []
        csv << []
      end
    end
  end

  def upload_csv(account_id, range, csv_content, frequency, _bitespeed_bot)
    start_date = range[:since].strftime('%Y-%m-%d')
    end_date = range[:until].strftime('%Y-%m-%d')

    # Determine the file name based on the frequency
    file_name = "#{frequency}_conversation_report_#{account_id}_#{end_date}.csv"

    # For testing locally, uncomment below
    Rails.logger.debug csv_content
    csv_url = file_name
    File.write(csv_url, csv_content)

    # Upload csv_content via ActiveStorage and print the URL
    # blob = ActiveStorage::Blob.create_and_upload!(
    #   io: StringIO.new(csv_content),
    #   filename: file_name,
    #   content_type: 'text/csv'
    # )

    # csv_url = Rails.application.routes.url_helpers.url_for(blob)

    # Send email with the CSV URL
    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: Account.find(account_id))

    if frequency == 'weekly'
      mailer.weekly_conversation_report(csv_url, start_date, end_date).deliver_now
    elsif frequency == 'daily'
      mailer.daily_conversation_report(csv_url, end_date).deliver_now
    end
  end
end
