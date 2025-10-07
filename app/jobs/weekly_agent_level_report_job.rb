require 'json'
require 'csv'

# rubocop:disable Metrics/ClassLength
class WeeklyAgentLevelReportJob < ApplicationJob
  queue_as :scheduled_jobs

  JOB_DATA_URL = 'https://bitespeed-app.s3.us-east-1.amazonaws.com/InternalAccess/cw-agent-level-report.json'.freeze

  def perform
    Rails.logger.info "Starting WeeklyAgentLevelReportJob at #{Time.current}"
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
    # job_data = JSON.parse(response.body, symbolize_names: true)[:agent_level_report]

    Rails.logger.info "Found #{job_data.length} jobs to process"

    job_data.each do |job|
      process_job(job)
    end

    Rails.logger.info "Completed WeeklyAgentLevelReportJob at #{Time.current}"
  end

  def generate_custom_report(account_id, range)
    Rails.logger.info "Starting custom agent level report generation for account_id: #{account_id}"
    set_statement_timeout

    current_date = Date.current
    process_account(account_id, current_date, range, 'custom')
    Rails.logger.info "Completed custom agent level report generation for account_id: #{account_id}"
  end

  private

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  def process_job(job)
    Rails.logger.info "Processing agent level job for account_id: #{job[:account_id]}, frequency: #{job[:frequency]}"

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
    Rails.logger.info "Starting to process agent level report for account_id: #{account_id} with frequency: #{frequency}"

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
      Rails.logger.info "No data found for account_id: #{account_id}"
    end
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def generate_report(account_id, range)
    Rails.logger.info "Generating agent level report for account_id: #{account_id} with range: #{range[:since]} to #{range[:until]}"

    account = Account.find(account_id)

    report_data = []

    # Get all agents (users) who are not bots
    agents = account.users.where.not('email LIKE ?', 'cx.%@bitespeed.co').order(:name)

    Rails.logger.info "Found #{agents.count} agents for account_id: #{account_id}"

    agents.each do |agent|
      Rails.logger.info "Processing agent: #{agent.name} (ID: #{agent.id})"

      # Get all inboxes this agent has access to
      inbox_ids = agent.inbox_members.pluck(:inbox_id)

      next if inbox_ids.empty?

      # For each inbox the agent has access to
      account.inboxes.where(id: inbox_ids).each do |inbox|
        Rails.logger.info "  Processing inbox: #{inbox.name} for agent: #{agent.name}"

        # Calculate metrics for this agent-inbox combination
        metrics = calculate_agent_inbox_metrics(account, agent.id, inbox.id, range)

        # Only add to report if agent handled conversations in this inbox
        next if metrics[:total_chats_handled].zero?

        report_data << {
          agent_id: agent.id,
          agent_name: agent.name,
          inbox_id: inbox.id,
          inbox_name: inbox.name,
          metrics: metrics
        }
      end
    end

    Rails.logger.info "Agent level report generated for account_id: #{account_id} - #{report_data.length} agent-inbox combinations"
    report_data
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def calculate_agent_inbox_metrics(account, agent_id, inbox_id, range)
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
        agents: [agent_id],
        labels: []
      },
      group_by: 'agent',
      metrics: %w[new_assigned reopened]
    }

    # Get metrics from CustomReportBuilder
    builder = V2::CustomReportBuilder.new(account, builder_input)
    report_result = builder.fetch_data

    # Extract new_assigned and reopened counts for this agent
    new_conversations_count = report_result[:data][:grouped_data][agent_id]['new_assigned'] || 0
    reopened_count = report_result[:data][:grouped_data][agent_id]['reopened'] || 0

    # 1. Total Chats Handled (Reopened + New Chat)
    total_chats_handled = new_conversations_count + reopened_count

    # 2. Total Chats Resolved
    resolved_conversations = account.reporting_events
                                    .where(name: 'conversation_resolved', user_id: agent_id, inbox_id: inbox_id)
                                    .where(created_at: range[:since]..range[:until])
                                    .distinct
                                    .count(:conversation_id)

    # 3. Avg Resolution Time (excluding pending/snoozed time)
    resolved_events = account.reporting_events
                             .where(name: 'conversation_resolved', user_id: agent_id, inbox_id: inbox_id)
                             .where(created_at: range[:since]..range[:until])

    # Calculate adjusted resolution time (excluding pending/snoozed)
    avg_resolution_time = calculate_avg_time_excluding_pending_snoozed(
      account, resolved_events, 'resolution'
    )

    # 4. Avg First Response Time (not affected by pending/snoozed)
    frt_events = account.reporting_events
                        .where(name: 'first_response', user_id: agent_id, inbox_id: inbox_id)
                        .where(created_at: range[:since]..range[:until])
    avg_first_response_time = frt_events.average(:value)&.to_f || 0

    # 5. Avg Response Time (excluding pending/snoozed time)
    response_events = account.reporting_events
                             .where(name: 'reply_time', user_id: agent_id, inbox_id: inbox_id)
                             .where(created_at: range[:since]..range[:until])

    # Calculate adjusted response time (excluding pending/snoozed)
    avg_response_time = calculate_avg_time_excluding_pending_snoozed(
      account, response_events, 'response'
    )

    # 6. CSAT Score
    csat_responses = account.csat_survey_responses
                            .where(assigned_agent_id: agent_id)
                            .joins(:conversation)
                            .where(conversations: { inbox_id: inbox_id })
                            .where(created_at: range[:since]..range[:until])
    avg_csat_score = csat_responses.average(:rating)&.to_f || 0

    {
      total_chats_handled: total_chats_handled,
      total_chats_resolved: resolved_conversations,
      avg_resolution_time: format_time(avg_resolution_time),
      avg_first_response_time: format_time(avg_first_response_time),
      avg_response_time: format_time(avg_response_time),
      csat_score: avg_csat_score.round(2)
    }
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def calculate_avg_time_excluding_pending_snoozed(account, events, metric_type)
    return 0 if events.empty?

    total_adjusted_time = 0
    count = 0

    events.each do |event|
      conversation_id = event.conversation_id
      original_time = event.value

      # Calculate time spent in pending/snoozed status for this conversation
      pending_snoozed_time = calculate_pending_snoozed_time(account, conversation_id)

      # Adjust the time by subtracting pending/snoozed duration
      adjusted_time = [original_time - pending_snoozed_time, 0].max

      total_adjusted_time += adjusted_time
      count += 1

      Rails.logger.debug do
        "Conversation #{conversation_id}: Original #{metric_type} time: #{original_time}s, " \
          "Pending/Snoozed: #{pending_snoozed_time}s, Adjusted: #{adjusted_time}s"
      end
    end

    count.zero? ? 0 : (total_adjusted_time / count).to_f
  end

  # rubocop:disable Metrics/MethodLength
  def calculate_pending_snoozed_time(account, conversation_id)
    # Get all status changes for this conversation
    statuses = ConversationStatus
               .where(conversation_id: conversation_id, account_id: account.id)
               .order(created_at: :asc)

    return 0 if statuses.empty?

    total_pending_snoozed_time = 0
    pending_start_time = nil
    snoozed_start_time = nil

    statuses.each do |status|
      case status.status
      when 'pending'
        pending_start_time ||= status.created_at
      when 'snoozed'
        snoozed_start_time ||= status.created_at
      when 'open', 'resolved'
        # Calculate duration if we were in pending
        if pending_start_time
          duration = status.created_at - pending_start_time
          total_pending_snoozed_time += duration
          pending_start_time = nil
        end

        # Calculate duration if we were in snoozed
        if snoozed_start_time
          duration = status.created_at - snoozed_start_time
          total_pending_snoozed_time += duration
          snoozed_start_time = nil
        end
      end
    end

    # If conversation is still pending/snoozed, calculate up to now
    total_pending_snoozed_time += (Time.current - pending_start_time) if pending_start_time

    total_pending_snoozed_time += (Time.current - snoozed_start_time) if snoozed_start_time

    total_pending_snoozed_time
  end
  # rubocop:enable Metrics/MethodLength

  def format_time(seconds)
    return '0s' if seconds.zero?

    hours = (seconds / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i
    secs = (seconds % 60).to_i

    if hours.positive?
      "#{hours}h #{minutes}m #{secs}s"
    elsif minutes.positive?
      "#{minutes}m #{secs}s"
    else
      "#{secs}s"
    end
  end

  # rubocop:disable Metrics/MethodLength
  def generate_csv(report_data, start_date, end_date, account_id)
    Rails.logger.info "Generating CSV for account_id: #{account_id}"

    CSV.generate(headers: true) do |csv|
      csv << ["Agent Level Report - Reporting period #{start_date} to #{end_date}"]
      csv << ['Note: Avg. Resolution Time and Avg. Response Time exclude pending/snoozed periods']
      csv << []

      # Headers
      headers = [
        'Agent Name',
        'Inbox Name',
        'Total Chats Handled (Reopened + New Chat)',
        'Total Chats Resolved',
        'Avg. Resolution Time (excl. pending/snoozed)',
        'Avg. First Response Time',
        'Avg. Response Time (excl. pending/snoozed)',
        'CSAT Score'
      ]

      csv << headers

      # Data rows
      report_data.each do |agent_data|
        metrics = agent_data[:metrics]
        csv << [
          agent_data[:agent_name],
          agent_data[:inbox_name],
          metrics[:total_chats_handled],
          metrics[:total_chats_resolved],
          metrics[:avg_resolution_time],
          metrics[:avg_first_response_time],
          metrics[:avg_response_time],
          metrics[:csat_score]
        ]
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def upload_csv(account_id, range, csv_content, frequency)
    Rails.logger.info "Starting CSV upload for account_id: #{account_id}, frequency: #{frequency}"

    start_date = range[:since].strftime('%Y-%m-%d')
    end_date = range[:until].strftime('%Y-%m-%d')

    # Determine the file name based on the frequency
    file_name = "#{frequency}_agent_level_report_#{account_id}_#{end_date}.csv"
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
      Rails.logger.info "Sending weekly agent level report email for account_id: #{account_id}"
      mailer.weekly_agent_level_report(csv_url, start_date, end_date).deliver_now
    when 'monthly'
      Rails.logger.info "Sending monthly agent level report email for account_id: #{account_id}"
      mailer.monthly_agent_level_report(csv_url, start_date, end_date).deliver_now
    else
      Rails.logger.info "Sending custom agent level report email for account_id: #{account_id}"
      mailer.custom_agent_level_report(csv_url, start_date, end_date).deliver_now
    end
  end
end
# rubocop:enable Metrics/ClassLength
