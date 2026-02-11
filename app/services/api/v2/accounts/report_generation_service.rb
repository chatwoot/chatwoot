class Api::V2::Accounts::ReportGenerationService
  attr_reader :account, :params, :current_user

  def initialize(account, params, current_user)
    @account = account
    @params = params
    @current_user = current_user
  end

  def generate_all_conversation_metrics
    filter_params = build_filter_params
    V2::Reports::AllConversationMetricsBuilder.new(account, filter_params).build
  end

  def generate_overview_summary
    filter_params = build_filter_params.merge(overview_summary_params)
    V2::Reports::OverviewSummaryBuilder.new(account, filter_params).build
  end

  def generate_agent_activity_data
    builder = V2::Reports::AgentActivityBuilder.new(account, agent_activity_params)
    {
      since: Time.zone.at(params[:since].to_i),
      until: Time.zone.at(params[:until].to_i),
      agents: builder.call
    }
  end

  def build_summary(method)
    builder = V2::Reports::Conversations::MetricBuilder
    current_summary = builder.new(account, current_summary_params).send(method)
    previous_summary = builder.new(account, previous_summary_params).send(method)
    current_summary.merge(previous: previous_summary)
  end

  def build_conversation_metrics
    V2::ReportBuilder.new(account, conversation_params).conversation_metrics
  end

  def build_bot_metrics
    V2::Reports::BotMetricsBuilder.new(account, bot_metrics_params).metrics
  end

  def format_date_range
    since_time = Time.zone.at(params[:since].to_i)
    until_time = Time.zone.at(params[:until].to_i)
    "#{since_time.strftime('%b %d, %Y')} - #{until_time.strftime('%b %d, %Y')}"
  end

  def queue_email_delivery(filter_params)
    recipient_email = params[:email].presence || current_user.email
    Reports::AllMetricsJob.perform_later(
      account.id,
      current_user.id,
      filter_params.merge(format: params[:format] || 'csv', email: recipient_email)
    )
    { message: I18n.t('reports.email_delivery.queued'), status: 'queued', email: recipient_email }
  end

  private

  def build_filter_params
    {
      since: params[:since],
      until: params[:until],
      user_ids: params[:user_ids],
      inbox_ids: params[:inbox_ids],
      team_ids: params[:team_ids],
      label_ids: params[:label_ids],
      time_since: params[:time_since],
      time_until: params[:time_until]
    }.compact
  end

  def overview_summary_params
    {
      type: :account,
      since: params[:since],
      until: params[:until],
      timezone_offset: params[:timezone_offset],
      business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours])
    }
  end

  def summary_report_params
    params.permit(
      :since,
      :until,
      :business_hours,
      :time_since,
      :time_until,
      user_ids: [],
      inbox_ids: [],
      team_ids: [],
      label_ids: []
    )
  end

  def agent_activity_params
    params.permit(:since, :until, :timezone_offset, :hide_inactive, team_ids: [], user_ids: [], inbox_ids: [])
  end

  def bot_metrics_params
    params.permit(:since, :until, inbox_ids: [])
  end

  def bot_summary_download_params
    {
      since: params[:since],
      until: params[:until],
      inbox_ids: params[:inbox_ids]&.reject(&:blank?)
    }
  end

  def common_params
    {
      type: params[:type].to_sym,
      id: params[:id],
      group_by: params[:group_by],
      business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours])
    }
  end

  def current_summary_params
    common_params.merge(
      since: range[:current][:since],
      until: range[:current][:until],
      timezone_offset: params[:timezone_offset],
      inbox_ids: params[:inbox_ids]&.reject(&:blank?)
    )
  end

  def previous_summary_params
    common_params.merge(
      since: range[:previous][:since],
      until: range[:previous][:until],
      timezone_offset: params[:timezone_offset],
      inbox_ids: params[:inbox_ids]&.reject(&:blank?)
    )
  end

  def conversation_params
    {
      type: params[:type].to_sym,
      user_id: params[:user_id],
      page: params[:page].presence || 1
    }
  end

  def range
    time_diff = params[:until].to_i - params[:since].to_i
    {
      current: { since: params[:since], until: params[:until] },
      previous: { since: (params[:since].to_i - time_diff).to_s, until: params[:since] }
    }
  end
end
