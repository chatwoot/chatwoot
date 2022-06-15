module Api::V2::Accounts::ReportsHelper
  def generate_agents_report
    Current.account.users.map do |agent|
      agent_report = generate_report({ type: :agent, id: agent.id })
      [agent.name] + generate_readable_report_metrics(agent_report)
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
      team_report = generate_report({ type: :team, id: team.id })
      [team.name] + generate_readable_report_metrics(team_report)
    end
  end

  def generate_labels_report
    Current.account.labels.map do |label|
      label_report = generate_report({ type: :label, id: label.id })
      [label.title] + generate_readable_report_metrics(label_report)
    end
  end

  def generate_report(report_params)
    V2::ReportBuilder.new(
      Current.account,
      report_params.merge(
        {
          since: params[:since],
          until: params[:until],
          business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours])
        }
      )
    ).summary
  end

  private

  def generate_readable_report_metrics(report_metric)
    [
      report_metric[:conversations_count],
      time_to_minutes(report_metric[:avg_first_response_time]),
      time_to_minutes(report_metric[:avg_resolution_time])
    ]
  end

  def time_to_minutes(time_in_seconds)
    (time_in_seconds / 60).to_i
  end
end
