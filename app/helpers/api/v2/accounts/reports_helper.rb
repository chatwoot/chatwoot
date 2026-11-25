module Api::V2::Accounts::ReportsHelper
  def generate_agents_report
    reports = V2::Reports::AgentSummaryBuilder.new(
      account: Current.account,
      params: build_params(type: :agent, inbox_id: params[:inbox_id].presence)
    ).build

    Current.account.users.filter_map do |agent|
      report = reports.find { |r| r[:id] == agent.id }
      # The builder drops agents with no part in the filtered inbox.
      next if report.blank?

      [agent.name] + generate_readable_report_metrics(report, handled: true)
    end
  end

  def generate_inboxes_report
    reports = V2::Reports::InboxSummaryBuilder.new(
      account: Current.account,
      params: build_params(type: :inbox, user_id: params[:user_id].presence)
    ).build

    Current.account.inboxes.filter_map do |inbox|
      report = reports.find { |r| r[:id] == inbox.id }
      # The builder drops inboxes the filtered agent never touched.
      next if report.blank?

      [inbox.name, inbox.channel&.name] + generate_readable_report_metrics(report, handled: true)
    end
  end

  def generate_teams_report
    reports = V2::Reports::TeamSummaryBuilder.new(
      account: Current.account,
      params: build_params(type: :team)
    ).build

    Current.account.teams.map do |team|
      report = reports.find { |r| r[:id] == team.id }
      [team.name] + generate_readable_report_metrics(report, handled: true)
    end
  end

  def generate_labels_report
    reports = V2::Reports::LabelSummaryBuilder.new(
      account: Current.account,
      params: build_params({})
    ).build

    reports.map do |report|
      [report[:name]] + generate_readable_report_metrics(report)
    end
  end

  def generate_conversations_report
    builder = V2::Reports::Conversations::MetricBuilder.new(Current.account, build_params(type: :account))
    summary = builder.summary

    [generate_conversation_report_metrics(summary)]
  end

  private

  def build_params(base_params)
    base_params.merge(
      {
        since: params[:since],
        until: params[:until],
        business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours])
      }
    )
  end

  def report_builder(report_params)
    V2::ReportBuilder.new(Current.account, build_params(report_params))
  end

  # Labels have no handled count: their summary is built apart from the others.
  def generate_readable_report_metrics(report, handled: false)
    [
      report[:conversations_count],
      Reports::TimeFormatPresenter.new(report[:avg_first_response_time]).format,
      Reports::TimeFormatPresenter.new(report[:avg_resolution_time]).format,
      Reports::TimeFormatPresenter.new(report[:avg_reply_time]).format,
      report[:resolved_conversations_count]
    ] + (handled ? [report[:handled_conversations_count]] : [])
  end

  def generate_conversation_report_metrics(summary)
    [
      summary[:conversations_count],
      summary[:incoming_messages_count],
      summary[:outgoing_messages_count],
      Reports::TimeFormatPresenter.new(summary[:avg_first_response_time]).format,
      Reports::TimeFormatPresenter.new(summary[:avg_resolution_time]).format,
      summary[:resolutions_count],
      Reports::TimeFormatPresenter.new(summary[:reply_time]).format
    ]
  end
end
