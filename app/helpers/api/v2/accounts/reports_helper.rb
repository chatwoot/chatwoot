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

  def generate_labels_report # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    current_range = range[:current]
    range_start = DateTime.strptime(current_range[:since].to_s, '%s')
    range_end = DateTime.strptime(current_range[:until].to_s, '%s')

    use_business_hours = ActiveModel::Type::Boolean.new.cast(params[:business_hours])

    # Get all labels for the account
    labels = Current.account.labels.to_a

    # Pre-fetch all conversation IDs grouped by label in a single query
    conversations_by_label = {}
    labels.each do |label|
      conversation_ids = Current.account.conversations
                                .tagged_with(label.title)
                                .where(created_at: range_start..range_end)
                                .pluck(:id)
      conversations_by_label[label.id] = conversation_ids
    end

    # Bulk fetch all reporting events for all conversation IDs at once
    all_conversation_ids = conversations_by_label.values.flatten.uniq

    first_response_events = ReportingEvent.where(
      name: 'first_response',
      account_id: Current.account.id,
      conversation_id: all_conversation_ids
    ).select(:conversation_id, :value, :value_in_business_hours).to_a

    resolution_events = ReportingEvent.where(
      name: :conversation_resolved,
      conversation_id: all_conversation_ids
    ).select(:conversation_id, :value, :value_in_business_hours).to_a

    # Get open conversations count for each label
    open_conversations_by_label = {}
    labels.each do |label|
      open_count = Current.account.conversations
                          .tagged_with(label.title)
                          .where(account_id: Current.account.id)
                          .open
                          .count
      open_conversations_by_label[label.id] = open_count
    end

    # Build the report for each label
    labels.map do |label|
      conversation_ids = conversations_by_label[label.id] || []

      # Filter events for this label's conversations
      label_first_response = first_response_events.select { |e| conversation_ids.include?(e.conversation_id) }
      label_resolutions = resolution_events.select { |e| conversation_ids.include?(e.conversation_id) }

      # Calculate averages
      frt_values = if use_business_hours
                     label_first_response.filter_map(&:value_in_business_hours)
                   else
                     label_first_response.filter_map(&:value)
                   end
      avg_frt = frt_values.any? ? frt_values.sum / frt_values.size.to_f : 0

      rt_values = if use_business_hours
                    label_resolutions.filter_map(&:value_in_business_hours)
                  else
                    label_resolutions.filter_map(&:value)
                  end
      avg_rt = rt_values.any? ? rt_values.sum / rt_values.size.to_f : 0

      [
        label.title,
        conversation_ids.size,
        Reports::TimeFormatPresenter.new(avg_frt).format,
        Reports::TimeFormatPresenter.new(avg_rt).format,
        '--', # online_time - not applicable for labels
        '--', # busy_time - not applicable for labels
        '--', # reply_time - not applicable for labels
        label_resolutions.size
      ]
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
