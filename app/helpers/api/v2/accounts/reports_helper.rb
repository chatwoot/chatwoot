module Api::V2::Accounts::ReportsHelper # rubocop:disable Metrics/ModuleLength
  def generate_agents_report
    current_range = range[:current]
    range_start = DateTime.strptime(current_range[:since].to_s, '%s')
    range_end = DateTime.strptime(current_range[:until].to_s, '%s')
    sanitized_range = { since: range_start, until: range_end }

    bitespeed_bot = Current.user.email.ends_with?('@bitespeed.co')

    AgentReportJob.new.generate_custom_report(Current.account, sanitized_range, params, bitespeed_bot)
  end

  def generate_conversations_report
    current_range = range[:current]
    range_start = DateTime.strptime(current_range[:since].to_s, '%s')
    range_end = DateTime.strptime(current_range[:until].to_s, '%s')
    sanitized_range = { since: range_start, until: range_end }

    bitespeed_bot = Current.user.email.ends_with?('@bitespeed.co')

    # background job to generate daily conversation report and mail it to the user
    DailyConversationReportJob.new.generate_custom_report(Current.account.id, sanitized_range, bitespeed_bot)

    []
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

  def generate_labels_report_for_combine # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    current_range = range[:current]
    range_start = DateTime.strptime(current_range[:since].to_s, '%s')
    range_end = DateTime.strptime(current_range[:until].to_s, '%s')

    use_business_hours = ActiveModel::Type::Boolean.new.cast(params[:business_hours])

    # Base query for conversation counts by label
    label_metrics = Conversation.connection.select_all(sanitize_sql_array([%{
      WITH label_conversations AS (
        SELECT
          cached_label_list,
          id,
          status
        FROM conversations
        WHERE account_id = ?
          AND created_at BETWEEN ? AND ?
          AND cached_label_list IS NOT NULL
          AND cached_label_list != ''
      )
      SELECT
        cached_label_list,
        COUNT(DISTINCT id) as conversations_count,
        COUNT(DISTINCT CASE WHEN status = 0 THEN id END) as open_count,
        COUNT(DISTINCT CASE WHEN status = 1 THEN id END) as resolved_count
      FROM label_conversations
      GROUP BY cached_label_list
    }, Current.account.id, range_start, range_end])).to_a

    # Process each label combo
    label_metrics.map do |metric|
      # Get conversation IDs for this label combination
      conversation_ids = Conversation.where(
        account_id: Current.account.id,
        created_at: range_start..range_end,
        cached_label_list: metric['cached_label_list']
      ).pluck(:id)

      avg_frt = calculate_first_response_metrics(conversation_ids, use_business_hours)

      avg_rt = calculate_resolution_metrics(conversation_ids, use_business_hours)

      [
        metric['cached_label_list'].delete(' '),
        metric['conversations_count'],
        Reports::TimeFormatPresenter.new(avg_frt || 0).format,
        Reports::TimeFormatPresenter.new(avg_rt || 0).format,
        '--', # online_time - not applicable for labels
        '--', # busy_time - not applicable for labels
        '--', # reply_time - not applicable for labels
        metric['resolved_count']
      ]
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

  def calculate_resolution_metrics(conversation_ids, use_business_hours)
    return 0 if conversation_ids.empty?

    resolution_events = ReportingEvent.where(
      name: :conversation_resolved,
      conversation_id: conversation_ids
    )

    avg_rt = if use_business_hours
               resolution_events.average(:value_in_business_hours)
             else
               resolution_events.average(:value)
             end

    avg_rt || 0
  end

  def calculate_first_response_metrics(conversation_ids, use_business_hours)
    return 0 if conversation_ids.empty?

    # Get first response metrics directly from reporting_events
    first_response_events = ReportingEvent.where(
      name: 'first_response',
      account_id: Current.account.id,
      conversation_id: conversation_ids
    )

    avg_frt = if use_business_hours
                first_response_events.average(:value_in_business_hours)
              else
                first_response_events.average(:value)
              end

    avg_frt || 0
  end

  def sanitize_sql_array(array)
    ActiveRecord::Base.send(:sanitize_sql_array, array)
  end
end
