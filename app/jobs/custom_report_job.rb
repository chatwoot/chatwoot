# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Layout/LineLength

require 'json'
require 'csv'

class CustomReportJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(account, input, email)
    set_statement_timeout

    report = build_report(account, input)

    Rails.logger.info "CUSTOM_REPORT_JOB: perform: report: #{report}"

    process_report(account, report, input, email)
  end

  private

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '60s'")
  end

  def parse_date_time(datetime)
    return datetime if datetime.is_a?(DateTime)
    return datetime.to_datetime if datetime.is_a?(Time) || datetime.is_a?(Date)

    DateTime.strptime(datetime, '%s')
  end

  def process_custom_time_range(time_period)
    case time_period[:type]
    when 'custom'
      parse_date_time(time_period[:start_date].to_s)...parse_date_time(time_period[:end_date].to_s)
    end
  end

  def build_report(account, input)
    Rails.logger.info "CUSTOM_REPORT_JOB: build_report: input: #{input}"
    V2::CustomReportBuilder.new(account, input).fetch_data
  end

  def process_report(account, report, input, email)
    if report[:data][:grouped_data].present?
      readable_report = generate_readable_report(account, report[:data][:grouped_data], report[:data][:grouped_data][:grouped_by])

      if readable_report.present?
        mail_csv(account, readable_report, input, report, email)
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

  def bot_handled_queries_report(account, input)
    # Conversation Link, Conversation Status, Resolved by, avg resolution time, Agent Assigned
    report = bot_handled_query_sql(account.id,
                                   { since: input[:filters][:time_period][:start_date], until: input[:filters][:time_period][:end_date] },
                                   process_custom_time_range(input[:filters][:time_period]))

    if report.present?
      Rails.logger.info "Data found for account_id: #{account.id}"

      csv_content = bot_handled_queries_generate_csv(report)

      file_name = "bot_handled_report_#{account.id}.csv"

      upload_csv(csv_content, file_name)
    else
      Rails.logger.info "No data found for account_id: #{account.id}"
    end
  end

  def bot_user(account_id)
    account = Account.find(account_id)
    query = account.users.where('email LIKE ?', 'cx.%@bitespeed.co')
    Rails.logger.info "bot_user query: #{query.to_sql}"
    query.first
  end

  def bot_handled_query_sql(account_id, range, time_range)
    base_query = Conversation.where(account_id: account_id, created_at: time_range)

    bot_user = bot_user(account_id)

    base_query = ConversationAssignment
                 .select('DISTINCT conversation_id')
                 .where(account_id: account_id, conversation_id: base_query.pluck(:id), assignee_id: bot_user.id)

    # bot_assignments = ConversationAssignment.where(assignee_id: bot_user.id)

    # conversations_assigned_by_bot = Conversation.where(id: bot_assignments
    # .select(:conversation_id)
    # .distinct
    # .joins('INNER JOIN conversation_assignments AS ca2 ON ca2.conversation_id = conversation_assignments.conversation_id')
    #                                         .where('ca2.assignee_id != ? AND ca2.created_at > conversation_assignments.created_at', bot_user.id).where(created_at: time_range))

    conversations_assigned_by_bot = ConversationAssignment
                                    .select("DISTINCT a1.conversation_id,
               FIRST_VALUE(a2.assignee_id) OVER (
                 PARTITION BY a1.conversation_id
                 ORDER BY a2.created_at
               ) as second_assignee_id")
                                    .from('conversation_assignments a1')
                                    .joins('JOIN conversation_assignments a2 ON a1.conversation_id = a2.conversation_id AND a1.created_at < a2.created_at')
                                    .where(a1: { assignee_id: bot_user.id })
                                    .where.not(a2: { assignee_id: bot_user.id })
                                    .where(a2: { created_at: time_range })

    sql = ActiveRecord::Base.send(:sanitize_sql_array, [<<-SQL.squish,
      WITH base_assignments AS (
        #{base_query.to_sql}
      ),
      latest_agent AS (
        #{conversations_assigned_by_bot.to_sql}
      )
      SELECT DISTINCT
          conversations.id AS conversation_id,
          conversations.display_id AS conversation_display_id,
          CONCAT('https://chat.bitespeed.co/app/accounts/', conversations.account_id, '/conversations/', conversations.display_id) AS conversation_link,
          conversations.created_at AS conversation_created_at,
          contacts.created_at AS customer_created_at,
          inboxes.name AS inbox_name,
          REPLACE(contacts.phone_number, '+', '') AS customer_phone_number,
          contacts.name AS customer_name,
          CASE
            WHEN conversations.status = 0 THEN 'open'
            WHEN conversations.status = 1 THEN 'resolved'
            WHEN conversations.status = 2 THEN 'pending'
            WHEN conversations.status = 3 THEN 'snoozed'
          END AS conversation_status,
          latest_conversation_resolved.value / 60.0 AS resolution_time_minutes,
          COALESCE(resolver.name, 'None') AS resolved_by,
          COALESCE(agent_user.name, 'None') AS agent_assigned_by_bot,
          conversations.cached_label_list AS labels
      FROM conversations
      JOIN inboxes ON conversations.inbox_id = inboxes.id
      JOIN contacts ON conversations.contact_id = contacts.id
      LEFT JOIN latest_agent ON conversations.id = latest_agent.conversation_id
      LEFT JOIN users agent_user ON latest_agent.second_assignee_id = agent_user.id
      LEFT JOIN account_users ON conversations.assignee_id = account_users.user_id
      LEFT JOIN users ON account_users.user_id = users.id
      LEFT JOIN LATERAL (
          SELECT value, user_id
          FROM reporting_events AS re
          WHERE re.conversation_id = conversations.id
          AND re.name = 'conversation_resolved'
          ORDER BY re.created_at DESC
          LIMIT 1
      ) AS latest_conversation_resolved ON true
      LEFT JOIN users resolver ON latest_conversation_resolved.user_id = resolver.id
      WHERE
          conversations.account_id = :account_id
          AND conversations.id IN (SELECT conversation_id FROM base_assignments)
    SQL
                                                        { account_id: account_id, since: Time.at(range[:since].to_i).utc,
                                                          until: Time.at(range[:until].to_i).utc }])

    Rails.logger.info "SQL_PRINTEND: #{sql}"

    ActiveRecord::Base.connection.exec_query(sql).to_a
  end

  def pre_sale_queries_report(account, input)
    # Pre sale conversation link, timestamp,  Customer name , Customer Phone number, Order ID, Created at,  Order Value
    report = pre_sale_query_sql(account.id, { since: input[:filters][:time_period][:start_date], until: input[:filters][:time_period][:end_date] })

    if report.present?
      Rails.logger.info "Data found for account_id: #{account.id}"

      phone_numbers = extract_phone_numbers(report)
      order_ids = fetch_order_ids(account.id, phone_numbers, process_custom_time_range(input[:filters][:time_period]))

      update_report_with_order_ids(report, order_ids)

      csv_content = pre_sale_queries_generate_csv(report)
      file_name = "pre_sale_report_#{account.id}.csv"

      upload_csv(csv_content, file_name)
    else
      Rails.logger.info "No data found for account_id: #{account.id}"
    end
  end

  def extract_phone_numbers(report)
    report
      .reject { |row| row['customer_phone_number'].nil? }
      .pluck('customer_phone_number')
  end

  def update_report_with_order_ids(report, order_ids)
    report.each do |row|
      matching_order = order_ids.find { |order| order['phoneNumber'] == row['customer_phone_number'] }
      row['order_id'] = matching_order ? matching_order['orderId'] : nil
      row['order_value'] = matching_order ? matching_order['orderValue'] : nil
    end
  end

  # def fetch_order_ids(account_id, phone_numbers)
  #   # url = URI('http://localhost:3000/previousOrdersByPhoneNumber')
  #   # TODO: update the url to new attribution one
  #   url = URI('https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/previousOrdersByPhoneNumber')

  #   http = Net::HTTP.new(url.host, url.port)
  #   http.use_ssl = (url.scheme == 'https')
  #   request = Net::HTTP::Post.new(url)
  #   request['Content-Type'] = 'application/json'
  #   request.body = JSON.dump({
  #                              'accountId': account_id.to_s,
  #                              'payload': phone_numbers_and_dates
  #                            })

  #   response = http.request(request)
  #   JSON.parse(response.body)['orders']
  # rescue StandardError => e
  #   Rails.logger.error "Failed to fetch order IDs: #{e.message}"
  #   []
  # end

  def fetch_shop_url(account_id)
    cache_key = "shop_url:#{account_id}"
    cached_url = Redis::Alfred.get(cache_key)
    return cached_url if cached_url.present?

    url = fetch_shop_url_from_api(account_id)
    Redis::Alfred.setex(cache_key, url, SHOP_URL_TTL) if url.present?
    url
  end

  def fetch_shop_url_from_api(account_id)
    response = HTTParty.get("https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/accountDetails/#{account_id}")
    return nil unless response.success?

    JSON.parse(response.body)['accountDetails']['shopUrl']
  rescue StandardError => e
    Rails.logger.error "Error fetching shop URL: #{e.message}"
    nil
  end

  def fetch_order_ids(account_id, phone_numbers, time_range)
    shop_url = fetch_shop_url(account_id)
    time_offset = 330

    params = {
      shopUrl: shop_url,
      timeOffset: time_offset
    }

    params[:timeQualifier] = 'Custom'
    params[:timeQuantifier] = {
      from: time_range&.begin&.strftime('%Y-%m-%d'),
      to: time_range&.end&.strftime('%Y-%m-%d')
    }.to_json
    params[:phoneNumbers] = phone_numbers

    response = HTTParty.get('https://43r09s4nl9.execute-api.us-east-1.amazonaws.com/chatwoot/botAttributions/phoneNumbers', query: params)
    Rails.logger.info "fetch_order_ids_response: #{response.body}"
    JSON.parse(response.body)['orders']
  rescue StandardError => e
    Rails.logger.error "Failed to fetch order IDs: #{e.message}"
    []
  end

  def pre_sale_query_sql(account_id, range)
    sql = ActiveRecord::Base.send(:sanitize_sql_array,
                                  [<<-SQL.squish,
      SELECT
          distinct conversations.id AS conversation_id,
          conversations.display_id AS conversation_display_id,
          CONCAT('https://chat.bitespeed.co/app/accounts/', conversations.account_id, '/conversations/', conversations.display_id) AS conversation_link,
          conversations.created_at AS conversation_created_at,
          contacts.created_at AS customer_created_at,
          REPLACE(contacts.phone_number, '+', '') AS customer_phone_number,
          contacts.name AS customer_name,
          conversations.cached_label_list AS labels
      FROM
          conversations
          JOIN contacts ON conversations.contact_id = contacts.id
      WHERE
          conversations.account_id = :account_id AND conversations.additional_attributes->>'intent' = 'PRE_SALES'
          AND conversations.created_at BETWEEN :since AND :until
                                  SQL
                                   { account_id: account_id, since: Time.at(range[:since].to_i).utc, until: Time.at(range[:until].to_i).utc }])

    ActiveRecord::Base.connection.exec_query(sql).to_a
  end

  def upload_csv(csv_content, file_name)
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

    Rails.application.routes.url_helpers.url_for(blob)
  end

  def mail_csv(account, readable_report, input, report, email)
    start_date = format_date(report[:time_range][:start_date])
    end_date = format_date(report[:time_range][:end_date])
    grouped_by = report[:data][:grouped_data][:grouped_by]

    grouped_by = 'Period' if grouped_by == 'working_hours'

    metrics = input[:metrics]

    csv_content = generate_csv(readable_report, grouped_by, metrics, start_date, end_date)

    file_name = "#{grouped_by}_report_#{account.id}_#{start_date}_#{end_date}.csv"

    csv_url = upload_csv(csv_content, file_name)

    bot_handled_csv_export_url = nil
    pre_sale_csv_export_url = nil

    bot_handled_csv_export_url = bot_handled_queries_report(account, input) if metrics.include?('bot_handled')

    pre_sale_csv_export_url = pre_sale_queries_report(account, input) if metrics.include?('pre_sale_queries')

    # Send email with the CSV URL
    subject = "#{grouped_by.capitalize} Report from #{start_date} to #{end_date} | #{account.name.capitalize}"
    body_html = <<~HTML
      <p>Hello,</p>

      <p>Please find attached the report you requested.</p>

      <p>
      Click <a href="#{csv_url}">here</a> to download the main report.
      #{bot_handled_csv_export_url ? "<br>Click <a href=\"#{bot_handled_csv_export_url}\">here</a> to download the bot handled queries report." : ''}
      #{pre_sale_csv_export_url ? "<br>Click <a href=\"#{pre_sale_csv_export_url}\">here</a> to download the pre-sale queries report." : ''}
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

  def pre_sale_queries_generate_csv(results)
    CSV.generate(headers: true) do |csv|
      csv << [
        'Conversation ID', 'Conversation Link', 'Customer Phone Number', 'Customer Name',
        'Labels', 'Order ID', 'Order Value', 'Conversation Created At', 'Contact Created At'
      ]
      results.each do |row|
        csv << [
          row['conversation_display_id'], row['conversation_link'], row['customer_phone_number'],
          row['customer_name'], row['labels'], row['order_id'], row['order_value'],
          row['conversation_created_at'], row['customer_created_at']
        ]
      end
    end
  end

  def bot_handled_queries_generate_csv(results)
    CSV.generate(headers: true) do |csv|
      csv << [
        'Conversation ID', 'Conversation Link', 'Customer Phone Number', 'Customer Name',
        'Labels', 'Conversation Status', 'Resolved by', 'Avg Resolution Time',
        'Agent Assigned', 'Conversation Created At', 'Contact Created At'
      ]
      results.each do |row|
        csv << [
          row['conversation_display_id'], row['conversation_link'], row['customer_phone_number'],
          row['customer_name'], row['labels'], row['conversation_status'], row['resolved_by'],
          row['resolution_time_minutes'], row['agent_assigned_by_bot'], row['conversation_created_at'],
          row['customer_created_at']
        ]
      end
    end
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
# rubocop:enable Layout/LineLength
