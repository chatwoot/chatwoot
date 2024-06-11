# rubocop:disable Metrics/ModuleLength
module Api::V2::Accounts::ReportsHelper
  def generate_agents_report
    Current.account.users.map do |agent|
      agent_report = report_builder({ type: :agent, id: agent.id }).summary
      [agent.name] + generate_readable_report_metrics(agent_report)
    end
  end

  def generate_conversations_report
    conversation_reports = generate_conversation_report(Current.account.id, range)
    conversation_reports.map do |conversation_report|
      [
        conversation_report['conversation_display_id'],
        conversation_report['inbox_name'],
        conversation_report['customer_name'],
        conversation_report['customer_phone_number'],
        conversation_report['customer_email'],
        conversation_report['customer_instagram_handle'],
        conversation_report['agent_name'],
        conversation_report['conversation_status'],
        conversation_report['first_response_time_minutes'],
        conversation_report['resolution_time_minutes'],
        conversation_report['labels']
      ]
    end
  end

  def generate_inboxes_report
    Current.account.inboxes.map do |inbox|
      inbox_report = generate_report({ type: :inbox, id: inbox.id })
      [inbox.name, inbox.channel&.name] + generate_readable_report_metrics(inbox_report)
    end
  end

  def generate_teams_report
    Current.account.teams.map do |team|
      team_report = report_builder({ type: :team, id: team.id }).summary
      [team.name] + generate_readable_report_metrics(team_report)
    end
  end

  def generate_labels_report
    Current.account.labels.map do |label|
      label_report = generate_report({ type: :label, id: label.id })
      [label.title] + generate_readable_report_metrics(label_report)
    end
  end

  def report_builder(report_params)
    V2::ReportBuilder.new(
      Current.account,
      report_params.merge(
        {
          since: params[:since],
          until: params[:until],
          business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours])
        }
      )
    )
  end

  def generate_report(report_params)
    report_builder(report_params).short_summary
  end

  private

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

  # rubocop:disable Metrics/MethodLength
  def generate_conversation_report(account_id, range)
    current_range = range[:current]
    range_start = DateTime.strptime(current_range[:since].to_s, '%s')
    range_end = DateTime.strptime(current_range[:until].to_s, '%s')
    key = params[:business_hours].present? && (params[:business_hours] == 'true') ? 'value_in_business_hours' : 'value'

    Rails.logger.info "key_for_query: #{key}"
    Rails.logger.info "params[:business_hours]: #{params[:business_hours]}"

    # Using ActiveRecord::Base directly for sanitization
    sql = <<-SQL.squish
      SELECT DISTINCT
        conversations.id AS conversation_id,
        conversations.display_id AS conversation_display_id,
        conversations.created_at AS created_at,
        contacts.created_at AS customer_created_at,
        inboxes.name AS inbox_name,
        contacts.name AS customer_name,
        REPLACE(contacts.phone_number, '+', '') AS customer_phone_number,
        contacts.email AS customer_email,
        contacts.additional_attributes ->> 'social_instagram_user_name' AS customer_instagram_handle,
        users.name AS agent_name,
        CASE
            WHEN conversations.status = 0 THEN 'open'
            WHEN conversations.status = 1 THEN 'resolved'
            WHEN conversations.status = 2 THEN 'pending'
            WHEN conversations.status = 3 THEN 'snoozed'
        END AS conversation_status,
        reporting_events_first_response.#{key} / 60.0 AS first_response_time_minutes,
        latest_conversation_resolved.#{key} / 60.0 AS resolution_time_minutes,
        conversations.cached_label_list AS labels
      FROM
        conversations
        JOIN inboxes ON conversations.inbox_id = inboxes.id
        JOIN contacts ON conversations.contact_id = contacts.id
        JOIN account_users ON conversations.assignee_id = account_users.user_id
        JOIN users ON account_users.user_id = users.id
        LEFT JOIN reporting_events AS reporting_events_first_response
            ON conversations.id = reporting_events_first_response.conversation_id
            AND reporting_events_first_response.name = 'first_response'
        LEFT JOIN LATERAL (
            SELECT #{key}
            FROM reporting_events AS re
            WHERE re.conversation_id = conversations.id
            AND re.name = 'conversation_resolved'
            ORDER BY re.created_at DESC
            LIMIT 1
        ) AS latest_conversation_resolved ON true
      WHERE
        conversations.account_id = $1
        AND conversations.updated_at BETWEEN $2 AND $3
    SQL

    ActiveRecord::Base.connection.exec_query(sql, 'SQL', [account_id, range_start, range_end]).to_a
  end

  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength
