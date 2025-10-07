require 'json'
require 'csv'

# rubocop:disable Metrics/ClassLength
class WeeklyInboxChannelReportJob < ApplicationJob
  queue_as :scheduled_jobs

  JOB_DATA_URL = 'https://bitespeed-app.s3.us-east-1.amazonaws.com/InternalAccess/cw-inbox-channel-report.json'.freeze

  def perform
    Rails.logger.info "Starting WeeklyInboxChannelReportJob at #{Time.current}"
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
    # job_data = JSON.parse(response.body, symbolize_names: true)[:inbox_channel_report]

    Rails.logger.info "Found #{job_data.length} jobs to process"

    job_data.each do |job|
      process_job(job)
    end

    Rails.logger.info "Completed WeeklyInboxChannelReportJob at #{Time.current}"
  end

  def generate_custom_report(account_id, range)
    Rails.logger.info "Starting custom inbox channel report generation for account_id: #{account_id}"
    set_statement_timeout

    current_date = Date.current
    process_account(account_id, current_date, range, 'custom')
    Rails.logger.info "Completed custom inbox channel report generation for account_id: #{account_id}"
  end

  private

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  def process_job(job)
    Rails.logger.info "Processing inbox channel job for account_id: #{job[:account_id]}, frequency: #{job[:frequency]}"

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
    Rails.logger.info "Starting to process inbox channel report for account_id: #{account_id} with frequency: #{frequency}"

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
    Rails.logger.info "Generating inbox channel report for account_id: #{account_id} with range: #{range[:since]} to #{range[:until]}"

    account = Account.find(account_id)

    report_data = []

    # Get all inboxes for the account
    inboxes = account.inboxes.order(:name)

    Rails.logger.info "Found #{inboxes.count} inboxes for account_id: #{account_id}"

    inboxes.each do |inbox|
      Rails.logger.info "Processing inbox: #{inbox.name} (ID: #{inbox.id}, Type: #{inbox.channel_type})"

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

      # Calculate metrics for this inbox
      metrics = calculate_inbox_metrics(account, inbox.id, range)

      report_data << {
        inbox_id: inbox.id,
        inbox_name: inbox.name,
        channel_type: channel_type,
        metrics: metrics
      }
    end

    Rails.logger.info "Inbox channel report generated for account_id: #{account_id} - #{report_data.length} inboxes"
    report_data
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def calculate_inbox_metrics(account, inbox_id, range)
    # Base conversation query for this specific inbox
    conversations = account.conversations.where(inbox_id: inbox_id, created_at: range[:since]..range[:until])

    # Get bot user
    bot_user = account.users.where('email LIKE ?', 'cx.%@bitespeed.co').first

    # Use V2::CustomReportBuilder for new_assigned and reopened metrics
    time_range = range[:since]..range[:until]

    # Build input for CustomReportBuilder
    builder_input = {
      filters: {
        time_period: {
          type: 'custom',
          start_date: range[:since].to_i,
          end_date: range[:until].to_i
        },
        business_hours: false,
        inboxes: [inbox_id],
        agents: nil,
        labels: []
      },
      group_by: 'inbox',
      metrics: %w[new_assigned reopened]
    }

    # Get metrics from CustomReportBuilder
    builder = V2::CustomReportBuilder.new(account, builder_input)
    report_result = builder.fetch_data

    # Extract new_assigned and reopened counts for this inbox
    new_conversations_count = report_result[:data][:grouped_data][inbox_id]['new_assigned'] || 0
    reopened_count = report_result[:data][:grouped_data][inbox_id]['reopened'] || 0

    # 1. Total Tickets Assigned (Reopened + New Chat)
    total_assigned = new_conversations_count + reopened_count

    # 2. Number of Chats Created (All conversations created in this period)
    new_chats_created = new_conversations_count

    # 3. Returning Customers (contacts with conversations before the range)
    contact_ids = conversations.pluck(:contact_id).uniq

    # Get contact IDs that had conversations before this time range
    returning_customer_ids = account.conversations
                                    .where(contact_id: contact_ids)
                                    .where('created_at < ?', range[:since])
                                    .distinct
                                    .pluck(:contact_id)

    returning_customers = returning_customer_ids.length

    # 4. New Customers (contacts with NO conversations before this range)
    new_customers = contact_ids.length - returning_customers

    # 5. Avg Resolution Time (excluding pending/snoozed time)
    resolved_events = account.reporting_events
                             .where(name: 'conversation_resolved', inbox_id: inbox_id, created_at: range[:since]..range[:until])

    # Calculate adjusted resolution time (excluding pending/snoozed)
    avg_resolution_time = calculate_avg_time_excluding_pending_snoozed(
      account, resolved_events, 'resolution'
    )

    # 6. Avg First Response Time (not affected by pending/snoozed)
    frt_events = account.reporting_events
                        .where(name: 'first_response', inbox_id: inbox_id, created_at: range[:since]..range[:until])
    avg_first_response_time = frt_events.average(:value)&.to_f || 0

    # 7. Avg Response Time (excluding pending/snoozed time)
    response_events = account.reporting_events
                             .where(name: 'reply_time', inbox_id: inbox_id, created_at: range[:since]..range[:until])

    # Calculate adjusted response time (excluding pending/snoozed)
    avg_response_time = calculate_avg_time_excluding_pending_snoozed(
      account, response_events, 'response'
    )

    # 8. CSAT Score
    csat_responses = account.csat_survey_responses
                            .joins(:conversation)
                            .where(conversations: { inbox_id: inbox_id })
                            .where(created_at: range[:since]..range[:until])
    avg_csat_score = csat_responses.average(:rating)&.to_f || 0

    # 9. Chats Handled by Bot
    chats_by_bot = bot_user.present? ? conversations.where(assignee_id: bot_user.id).count : 0

    # 10. Chats Handled by Agent (excluding bot)
    chats_by_agent = if bot_user.present?
                       conversations.where.not(assignee_id: [bot_user.id,
                                                             nil]).count
                     else
                       conversations.where.not(assignee_id: nil).count
                     end

    # 11. Bot to Agent Handoff - use existing bot_assign_to_agent metric
    bot_to_agent_handoff = calculate_bot_assign_to_agent(account, [inbox_id], range[:since], range[:until])

    {
      total_tickets_assigned: total_assigned,
      new_chats_created: new_chats_created,
      returning_customers: returning_customers,
      new_customers: new_customers,
      avg_resolution_time: format_time(avg_resolution_time),
      avg_first_response_time: format_time(avg_first_response_time),
      avg_response_time: format_time(avg_response_time),
      csat_score: avg_csat_score.round(2),
      chats_handled_by_bot: chats_by_bot,
      chats_handled_by_agent: chats_by_agent,
      bot_to_agent_handoff: bot_to_agent_handoff
    }
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def calculate_bot_assign_to_agent(account, inbox_ids, since_time, until_time)
    # Find bot user
    bot_user = account.users.where('email LIKE ?', 'cx.%@bitespeed.co').first
    return 0 unless bot_user.present?

    # Find all conversations where assignment changed from bot to someone else
    # Using the same logic as bot_assign_to_agent in custom_report_helper.rb
    conversations_assigned_by_bot = ConversationAssignment
                                    .select('DISTINCT a2.conversation_id')
                                    .from('conversation_assignments a1')
                                    .joins('JOIN conversation_assignments a2 ON a1.conversation_id = a2.conversation_id AND a1.created_at < a2.created_at')
                                    .where(a1: { assignee_id: bot_user.id, account_id: account.id })
                                    .where.not(a2: { assignee_id: bot_user.id })
                                    .where(a2: { created_at: since_time..until_time })

    # Count conversations in the time range and matching inboxes
    account.conversations
           .where(id: conversations_assigned_by_bot)
           .where(inbox_id: inbox_ids)
           .where(created_at: since_time..until_time)
           .count
  end

  def calculate_avg_time_excluding_pending_snoozed(account, events, _metric_type)
    return 0 if events.empty?

    total_adjusted_time = 0
    count = 0

    events.each do |event|
      original_time = event.value

      # Calculate pending/snoozed time for this conversation
      pending_snoozed_time = calculate_pending_snoozed_time(account, event.conversation_id)

      # Adjust by subtracting pending/snoozed duration
      adjusted_time = [original_time - pending_snoozed_time, 0].max

      total_adjusted_time += adjusted_time
      count += 1
    end

    count.zero? ? 0 : (total_adjusted_time / count).to_f
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def calculate_pending_snoozed_time(account, conversation_id)
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
        # End pending period if it was active
        if pending_start_time
          total_pending_snoozed_time += (status.created_at - pending_start_time)
          pending_start_time = nil
        end
        # End snoozed period if it was active
        if snoozed_start_time
          total_pending_snoozed_time += (status.created_at - snoozed_start_time)
          snoozed_start_time = nil
        end
      end
    end

    # If conversation is still pending/snoozed, count time up to now
    total_pending_snoozed_time += (Time.current - pending_start_time) if pending_start_time
    total_pending_snoozed_time += (Time.current - snoozed_start_time) if snoozed_start_time

    total_pending_snoozed_time
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
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
      csv << ["Inbox Level Report - Reporting period #{start_date} to #{end_date}"]
      csv << ['Note: Avg. Resolution Time and Avg. Response Time exclude pending/snoozed periods']
      csv << []

      # Headers
      headers = [
        'Inbox Name',
        'Channel Type',
        'Total Tickets Assigned (Reopened + New Chat)',
        'Number of Chats Created (Old Customers + New Customers)',
        'Returning Customers',
        'New Customers',
        'Avg. Resolution Time (excl. pending/snoozed)',
        'Avg. First Response Time',
        'Avg. Response Time (excl. pending/snoozed)',
        'CSAT Score',
        'Chats Handled by Bot',
        'Chats Handled by Agent',
        'Chat handled by the bot, carry forwarded to the Agent'
      ]

      csv << headers

      # Data rows
      report_data.each do |inbox_data|
        metrics = inbox_data[:metrics]
        csv << [
          inbox_data[:inbox_name],
          inbox_data[:channel_type],
          metrics[:total_tickets_assigned],
          metrics[:new_chats_created],
          metrics[:returning_customers],
          metrics[:new_customers],
          metrics[:avg_resolution_time],
          metrics[:avg_first_response_time],
          metrics[:avg_response_time],
          metrics[:csat_score],
          metrics[:chats_handled_by_bot],
          metrics[:chats_handled_by_agent],
          metrics[:bot_to_agent_handoff]
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
    file_name = "#{frequency}_inbox_channel_report_#{account_id}_#{end_date}.csv"
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
      Rails.logger.info "Sending weekly inbox channel report email for account_id: #{account_id}"
      mailer.weekly_inbox_channel_report(csv_url, start_date, end_date).deliver_now
    when 'monthly'
      Rails.logger.info "Sending monthly inbox channel report email for account_id: #{account_id}"
      mailer.monthly_inbox_channel_report(csv_url, start_date, end_date).deliver_now
    else
      Rails.logger.info "Sending custom inbox channel report email for account_id: #{account_id}"
      mailer.custom_inbox_channel_report(csv_url, start_date, end_date).deliver_now
    end
  end
end
# rubocop:enable Metrics/ClassLength
