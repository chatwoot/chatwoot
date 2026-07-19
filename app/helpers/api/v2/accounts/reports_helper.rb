module Api::V2::Accounts::ReportsHelper
  def generate_agents_report
    reports = V2::Reports::AgentSummaryBuilder.new(
      account: Current.account,
      params: build_params(type: :agent)
    ).build

    rows = Current.account.users.map do |agent|
      report = reports.find { |r| r[:id] == agent.id } || empty_report
      { label: agent.name, report: report }
    end

    enrich_summary_export_rows(rows)
  end

  def generate_inboxes_report
    reports = V2::Reports::InboxSummaryBuilder.new(
      account: Current.account,
      params: build_params(type: :inbox)
    ).build

    rows = Current.account.inboxes.map do |inbox|
      report = reports.find { |r| r[:id] == inbox.id } || empty_report
      { label: [inbox.name, inbox.channel&.name], report: report }
    end

    enrich_summary_export_rows(rows)
  end

  def generate_teams_report
    reports = V2::Reports::TeamSummaryBuilder.new(
      account: Current.account,
      params: build_params(type: :team)
    ).build

    rows = Current.account.teams.map do |team|
      report = reports.find { |r| r[:id] == team.id } || empty_report
      { label: team.name, report: report }
    end

    enrich_summary_export_rows(rows)
  end

  def generate_labels_report
    reports = V2::Reports::LabelSummaryBuilder.new(
      account: Current.account,
      params: build_params({})
    ).build

    rows = reports.map do |report|
      { label: report[:name], report: report }
    end

    enrich_summary_export_rows(rows)
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

  def empty_report
    {
      conversations_count: 0,
      avg_first_response_time: 0,
      avg_resolution_time: 0,
      avg_reply_time: 0,
      resolved_conversations_count: 0
    }
  end

  def enrich_summary_export_rows(rows)
    total_conversations = rows.sum { |row| row[:report][:conversations_count].to_i }
    total_resolutions = rows.sum { |row| row[:report][:resolved_conversations_count].to_i }

    export_rows = rows.map do |row|
      Array(row[:label]) + generate_readable_report_metrics(row[:report]) + [
        share_percent(row[:report][:conversations_count], total_conversations)
      ]
    end

    label_width = Array(rows.first&.dig(:label)).size
    label_width = 1 if label_width.zero?

    totals_label = Array.new(label_width, nil)
    totals_label[0] = I18n.t('reports.export_total')
    # Metrics columns: conversations, frt, art, reply, resolutions, share
    totals_row = totals_label + [
      total_conversations,
      nil,
      nil,
      nil,
      total_resolutions,
      share_percent(total_conversations, total_conversations)
    ]

    export_rows + [totals_row]
  end

  def share_percent(count, total)
    return '0%' if total.to_i.zero?

    "#{(count.to_f / total * 100).round(1)}%"
  end

  def generate_readable_report_metrics(report)
    [
      report[:conversations_count],
      Reports::TimeFormatPresenter.new(report[:avg_first_response_time]).format,
      Reports::TimeFormatPresenter.new(report[:avg_resolution_time]).format,
      Reports::TimeFormatPresenter.new(report[:avg_reply_time]).format,
      report[:resolved_conversations_count]
    ]
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
