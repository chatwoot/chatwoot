module Api::V2::Accounts::ReportsHelper
  def generate_agents_report
    reports = V2::Reports::AgentSummaryBuilder.new(
      account: Current.account,
      params: build_params_with_filters
    ).build

    Current.account.users.map do |agent|
      report = reports.find { |r| r[:id] == agent.id }
      next unless report
      
      [agent.name] + generate_readable_report_metrics(report)
    end.compact
  end

  def generate_inboxes_report
    reports = V2::Reports::InboxSummaryBuilder.new(
      account: Current.account,
      params: build_params_with_filters
    ).build

    Current.account.inboxes.map do |inbox|
      report = reports.find { |r| r[:id] == inbox.id }
      next unless report
      
      [inbox.name, inbox.channel&.name] + generate_readable_report_metrics(report)
    end.compact
  end

  def generate_teams_report
    reports = V2::Reports::TeamSummaryBuilder.new(
      account: Current.account,
      params: build_params_with_filters
    ).build

    Current.account.teams.map do |team|
      report = reports.find { |r| r[:id] == team.id }
      next unless report
      
      [team.name] + generate_readable_report_metrics(report)
    end.compact
  end

  def generate_labels_report
    reports = V2::Reports::LabelSummaryBuilder.new(
      account: Current.account,
      params: build_params_with_filters
    ).build

    reports.map do |report|
      [report[:name]] + generate_readable_report_metrics(report)
    end
  end

  def generate_bots_report
    V2::Reports::BotSummaryReportBuilder.new(
      account: Current.account,
      params: build_params_for_bots
    ).build
  end

  def generate_conversations_report
    builder = V2::Reports::Conversations::MetricBuilder.new(Current.account, build_params(type: :account))
    summary = builder.summary

    [generate_conversation_report_metrics(summary)]
  end

  private

  def build_params_with_filters
    {
      since: params[:since],
      until: params[:until],
      business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours]),
      user_ids: params[:user_ids]&.reject(&:blank?),
      inbox_ids: params[:inbox_ids]&.reject(&:blank?),
      team_ids: params[:team_ids]&.reject(&:blank?),
      label_ids: params[:label_ids]&.reject(&:blank?),
      time_since: params[:time_since],
      time_until: params[:time_until]
    }.compact
  end

  def build_params_for_bots
    {
      since: params[:since],
      until: params[:until],
      inbox_ids: params[:inbox_ids]&.reject(&:blank?)
    }.compact
  end

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

  def generate_readable_report_metrics(report)
    [
      report[:conversations_count],
      Reports::TimeFormatPresenter.new(report[:avg_first_response_time]).format,
      Reports::TimeFormatPresenter.new(report[:avg_resolution_time]).format,
      Reports::TimeFormatPresenter.new(report[:avg_reply_time]).format,
      report[:resolved_conversations_count],
      Reports::TimeFormatPresenter.new(report[:agent_chat_duration]).format,
      format_csat_score(report[:csat_satisfaction_score])
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

  def format_csat_score(score)
    score ? "#{score}%" : '--'
  end

  def format_date_range
    {
      since: Time.zone.at(params[:since].to_i),
      until: Time.zone.at(params[:until].to_i)
    }
  end
end
