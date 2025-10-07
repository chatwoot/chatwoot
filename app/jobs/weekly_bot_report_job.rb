require 'json'
require 'csv'

# rubocop:disable Metrics/ClassLength
class WeeklyBotReportJob < ApplicationJob
  queue_as :scheduled_jobs

  JOB_DATA_URL = 'https://bitespeed-app.s3.us-east-1.amazonaws.com/InternalAccess/cw-bot-report.json'.freeze

  def perform
    Rails.logger.info "Starting WeeklyBotReportJob at #{Time.current}"
    set_statement_timeout

    # Hardcoded test data
    job_data = [
      {
        account_id: 702,
        frequency: 'weekly',
        report_time: '09:00'
      }
    ]

    # Uncomment below to fetch from S3 in production
    # Rails.logger.info "Fetching job data from URL: #{JOB_DATA_URL}"
    # response = HTTParty.get(JOB_DATA_URL)
    # job_data = JSON.parse(response.body, symbolize_names: true)[:bot_report]

    Rails.logger.info "Found #{job_data.length} jobs to process"

    job_data.each do |job|
      process_job(job)
    end

    Rails.logger.info "Completed WeeklyBotReportJob at #{Time.current}"
  end

  def generate_custom_report(account_id, range)
    Rails.logger.info "Starting custom bot report generation for account_id: #{account_id}"
    set_statement_timeout

    current_date = Date.current
    process_account(account_id, current_date, range, 'custom')
    Rails.logger.info "Completed custom bot report generation for account_id: #{account_id}"
  end

  private

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  def process_job(job)
    Rails.logger.info "Processing bot job for account_id: #{job[:account_id]}, frequency: #{job[:frequency]}"

    current_date = Date.current
    current_day = current_date.wday

    report_time = job[:report_time]

    Rails.logger.info "Job config - report_time: #{report_time}"

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
    process_account(job[:account_id], current_date, range, job[:frequency])
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/MethodLength

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '60s'")
  end

  def process_account(account_id, _current_date, range, frequency = 'weekly')
    Rails.logger.info "Starting to process bot report for account_id: #{account_id} with frequency: #{frequency}"

    report = generate_report(account_id, range)

    if report.present?
      Rails.logger.info "Data found for account_id: #{account_id}"

      start_date = range[:since].strftime('%Y-%m-%d')
      end_date = range[:until].strftime('%Y-%m-%d')

      Rails.logger.info "Generating CSV for account_id: #{account_id}"
      csv_content = generate_csv(report, start_date, end_date, account_id)
      Rails.logger.info "CSV generated for account_id: #{account_id} - #{csv_content.bytesize} bytes"

      upload_csv(account_id, range, csv_content, frequency)
    else
      Rails.logger.info "No bot data found for account_id: #{account_id}"
    end
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def generate_report(account_id, range)
    Rails.logger.info "Generating bot report for account_id: #{account_id} with range: #{range[:since]} to #{range[:until]}"

    account = Account.find(account_id)

    # Get bot users
    bot_users = account.users.where('email LIKE ?', 'cx.%@bitespeed.co')

    if bot_users.empty?
      Rails.logger.info "No bot users found for account_id: #{account_id}"
      return []
    end

    Rails.logger.info "Found #{bot_users.count} bot users for account_id: #{account_id}"

    report_data = []

    bot_users.each do |bot_user|
      Rails.logger.info "Processing bot user: #{bot_user.name} (ID: #{bot_user.id})"

      # Get all inboxes where this bot has handled conversations
      inbox_ids = account.conversations
                         .where(assignee_id: bot_user.id, created_at: range[:since]..range[:until])
                         .distinct
                         .pluck(:inbox_id)

      inbox_ids.each do |inbox_id|
        inbox = account.inboxes.find_by(id: inbox_id)
        next unless inbox

        Rails.logger.info "Processing bot-inbox combination: #{bot_user.name} - #{inbox.name}"

        # Determine channel type display name
        channel_type = case inbox.channel_type
                       when 'Channel::Whatsapp'
                         'WhatsApp'
                       when 'Channel::Email'
                         'Email'
                       when 'Channel::FacebookPage'
                         'Facebook/Instagram'
                       when 'Channel::WebWidget'
                         'Web Widget'
                       when 'Channel::Api'
                         'API'
                       when 'Channel::TwilioSms'
                         'SMS'
                       else
                         inbox.channel_type&.split('::')&.last || 'Unknown'
                       end

        # Calculate metrics for this bot-inbox combination
        metrics = calculate_bot_metrics(account, bot_user.id, inbox_id, range)

        # Only include if bot handled conversations
        next if metrics[:total_chats_handled].zero?

        report_data << {
          bot_name: bot_user.name,
          inbox_name: inbox.name,
          channel_type: channel_type,
          metrics: metrics
        }
      end
    end

    Rails.logger.info "Bot report generated for account_id: #{account_id} - #{report_data.length} bot-inbox combinations"
    report_data
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def calculate_bot_metrics(account, bot_user_id, inbox_id, range)
    # Use V2::CustomReportBuilder for new_assigned and reopened metrics
    builder_input = {
      filters: {
        time_period: {
          type: 'custom',
          start_date: range[:since].to_i,
          end_date: range[:until].to_i
        },
        business_hours: false,
        inboxes: [inbox_id],
        agents: [bot_user_id],
        labels: []
      },
      group_by: 'agent',
      metrics: %w[new_assigned reopened]
    }

    # Get metrics from CustomReportBuilder
    builder = V2::CustomReportBuilder.new(account, builder_input)
    report_result = builder.fetch_data

    # Extract new_assigned and reopened counts for this bot
    new_conversations_count = report_result[:data][:grouped_data][bot_user_id]['new_assigned'] || 0
    reopened_count = report_result[:data][:grouped_data][bot_user_id]['reopened'] || 0

    # 1. Total Chats Handled (Reopened + New Chat)
    total_chats_handled = new_conversations_count + reopened_count

    # 2. Total Chats Assigned to an Agent (Bot-to-Agent Handoff)
    # Find all conversations where assignment changed from bot to someone else
    conversations_assigned_by_bot = ConversationAssignment
                                    .select('DISTINCT a2.conversation_id')
                                    .from('conversation_assignments a1')
                                    .joins('JOIN conversation_assignments a2 ON a1.conversation_id = a2.conversation_id AND a1.created_at < a2.created_at')
                                    .where(a1: { assignee_id: bot_user_id, account_id: account.id })
                                    .where.not(a2: { assignee_id: bot_user_id })
                                    .where(a2: { created_at: range[:since]..range[:until] })

    total_assigned_to_agent = account.conversations
                                     .where(id: conversations_assigned_by_bot)
                                     .where(inbox_id: inbox_id)
                                     .where(created_at: range[:since]..range[:until])
                                     .count

    # 3. CSAT Score
    csat_responses = account.csat_survey_responses
                            .joins(:conversation)
                            .where(conversations: { assignee_id: bot_user_id, inbox_id: inbox_id })
                            .where(created_at: range[:since]..range[:until])
    avg_csat_score = csat_responses.average(:rating)&.to_f || 0

    {
      total_chats_handled: total_chats_handled,
      total_assigned_to_agent: total_assigned_to_agent,
      csat_score: avg_csat_score.round(2)
    }
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def generate_csv(report_data, start_date, end_date, account_id)
    Rails.logger.info "Generating CSV for account_id: #{account_id}"

    CSV.generate(headers: true) do |csv|
      csv << ["Bitespeed Bot Report - Reporting period #{start_date} to #{end_date}"]
      csv << []

      # Headers
      headers = [
        'Bot Name',
        'Inbox Name',
        'Channel Type',
        'Total Chats Handled (Reopened + New Chat)',
        'Total Chats Assigned to an Agent',
        'CSAT Score'
      ]

      csv << headers

      # Data rows
      report_data.each do |bot_data|
        metrics = bot_data[:metrics]
        csv << [
          bot_data[:bot_name],
          bot_data[:inbox_name],
          bot_data[:channel_type],
          metrics[:total_chats_handled],
          metrics[:total_assigned_to_agent],
          metrics[:csat_score]
        ]
      end
    end
  end

  def upload_csv(account_id, range, csv_content, frequency)
    Rails.logger.info "Starting CSV upload for account_id: #{account_id}, frequency: #{frequency}"

    start_date = range[:since].strftime('%Y-%m-%d')
    end_date = range[:until].strftime('%Y-%m-%d')

    # Determine the file name based on the frequency
    file_name = "#{frequency}_bot_report_#{account_id}_#{end_date}.csv"
    Rails.logger.info "File name: #{file_name}"

    csv_url = upload_to_storage(account_id, file_name, csv_content)
    send_email_notification(account_id, csv_url, start_date, end_date, frequency)

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

  def send_email_notification(account_id, csv_url, start_date, end_date, frequency)
    Rails.logger.info "Sending email notification for account_id: #{account_id}"
    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: Account.find(account_id))

    case frequency
    when 'weekly'
      Rails.logger.info "Sending weekly bot report email for account_id: #{account_id}"
      mailer.weekly_bot_report(csv_url, start_date, end_date).deliver_now
    when 'monthly'
      Rails.logger.info "Sending monthly bot report email for account_id: #{account_id}"
      mailer.monthly_bot_report(csv_url, start_date, end_date).deliver_now
    else
      Rails.logger.info "Sending custom bot report email for account_id: #{account_id}"
      mailer.custom_bot_report(csv_url, start_date, end_date).deliver_now
    end
  end
end
# rubocop:enable Metrics/ClassLength
