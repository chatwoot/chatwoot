module Api::V2::Accounts::ReportsHelper
  def generate_agents_report
    Current.account.users.map do |agent|
      agent_report = report_builder({ type: :agent, id: agent.id }).summary
      [agent.name] + generate_readable_report_metrics(agent_report)
    end
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
end
