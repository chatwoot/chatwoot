require 'json'
require 'csv'

class AgentReportJob < ApplicationJob
  def generate_custom_report(account, range, params, bitespeed_bot)
    set_statement_timeout

    process_account(account, range, params, bitespeed_bot, 'custom')
  end

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '60s'")
  end

  def report_builder(report_params)
    V2::ReportBuilder.new(
      Current.account,
      report_params
    )
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

  def process_account(account, range, params, bitespeed_bot, frequency = 'daily')
    report = generate_report(account, params)

    if report.present?
      Rails.logger.info "Data found for account_id: #{account.id}"

      start_date = range[:since].strftime('%Y-%m-%d')
      end_date = range[:until].strftime('%Y-%m-%d')

      csv_content = generate_csv(report, start_date, end_date)
      upload_csv(account.id, range, csv_content, frequency, bitespeed_bot)
    else
      Rails.logger.info "No data found for account_id: #{account.id}"
    end
  end

  def generate_report(account, params)
    account.users.map do |agent|
      agent_report = report_builder({ type: :agent, id: agent.id, since: params[:since], until: params[:until],
                                      business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours]) }).summary
      [agent.name] + generate_readable_report_metrics(agent_report)
    end
  end

  def generate_csv(results, start_date, end_date)
    CSV.generate(headers: true) do |csv|
      csv << ["Reporting period #{start_date} to #{end_date}"]
      csv << []
      csv << [
        'Agent name', 'Assigned conversations', 'Avg first response time', 'Avg resolution time', 'Online time',
        'Busy time', 'Avg customer waiting time', 'Resolution Count'
      ]
      results.each do |row|
        csv << row
      end
    end
  end

  def upload_csv(account_id, range, csv_content, frequency, bitespeed_bot)
    # Determine the file name based on the frequency
    start_date = range[:since].strftime('%Y-%m-%d')
    end_date = range[:until].strftime('%Y-%m-%d')

    file_name = "#{frequency}_agent_report_#{account_id}_#{end_date}.csv"

    # For testing locally, uncomment below
    # puts csv_content
    # csv_url = file_name
    # File.write(csv_url, csv_content)

    # return;
    # Upload csv_content via ActiveStorage and print the URL
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(csv_content),
      filename: file_name,
      content_type: 'text/csv'
    )

    csv_url = Rails.application.routes.url_helpers.url_for(blob)

    # Send email with the CSV URL
    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: Account.find(account_id))

    mailer.custom_agent_report(csv_url, start_date, end_date, bitespeed_bot).deliver_now
  end
end
