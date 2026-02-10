class Api::V2::Accounts::ReportsController < Api::V1::Accounts::BaseController
  include Api::V2::Accounts::ReportsHelper
  include Api::V2::Accounts::HeatmapHelper

  before_action :check_authorization

  def index
    builder = V2::Reports::Conversations::ReportBuilder.new(Current.account, report_params)
    data = builder.timeseries
    render json: data
  end

  def all_conversation_metrics_download
    filter_params = build_filter_params

    return handle_email_delivery(filter_params) if params[:send_email] == 'true'

    @report_data = V2::Reports::AllConversationMetricsBuilder.new(Current.account, filter_params).build

    respond_to do |format|
      format.csv { generate_csv('all_conversation_metrics', 'api/v2/accounts/reports/all_conversation_metrics') }
      format.xlsx { generate_xlsx('all_conversation_metrics', 'api/v2/accounts/reports/all_conversation_metrics') }
      format.any { generate_csv('all_conversation_metrics', 'api/v2/accounts/reports/all_conversation_metrics') }
    end
  end

  def summary
    render json: build_summary(:summary)
  end

  def bot_summary
    render json: build_summary(:bot_summary)
  end

  def agent_activity
    return render_missing_params_error unless valid_agent_activity_params?

    build_agent_activity_data

    respond_to do |format|
      format.csv  { generate_csv('agent_activity_report', 'api/v2/accounts/reports/agent_activity') }
      format.xlsx { generate_xlsx('agent_activity_report', 'api/v2/accounts/reports/agent_activity') }
      format.any  { generate_csv('agent_activity_report', 'api/v2/accounts/reports/agent_activity') }
    end
  end

  def bot_summary_download
    @report_data = generate_bots_report
    @date_range = format_date_range

    respond_to do |format|
      format.csv  { generate_csv('bot_summary', 'api/v2/accounts/reports/bot_summary') }
      format.xlsx { generate_xlsx('bot_summary', 'api/v2/accounts/reports/bot_summary') }
      format.any  { generate_csv('bot_summary', 'api/v2/accounts/reports/bot_summary') }
    end
  end

  def overview_summary
    filter_params = build_filter_params.merge(overview_summary_params)

    Rails.logger.info "1PARAMS: #{params[:since]}, #{params[:until]}, offset: #{params[:timezone_offset]}"
    Rails.logger.info "1UTC TIME: #{Time.at(params[:since].to_i).utc} - #{Time.at(params[:until].to_i).utc}"

    result = V2::Reports::OverviewSummaryBuilder.new(Current.account, filter_params).build

    @conversation_metrics = result[:conversation_metrics]
    @agent_status         = result[:agent_status]
    @summary              = result[:summary]
    @date_range           = result[:date_range]

    respond_to do |format|
      format.csv  { generate_csv('overview_summary', 'api/v2/accounts/reports/overview_summary') }
      format.xlsx { generate_xlsx('overview_summary', 'api/v2/accounts/reports/overview_summary') }
      format.any  { generate_csv('overview_summary', 'api/v2/accounts/reports/overview_summary') }
    end
  end

  def agents
    @report_data = generate_agents_report

    respond_to do |format|
      format.csv  { generate_csv('agents_report', 'api/v2/accounts/reports/agents') }
      format.xlsx { generate_xlsx('agents_report', 'api/v2/accounts/reports/agents') }
      format.any  { generate_csv('agents_report', 'api/v2/accounts/reports/agents') }
    end
  end

  def inboxes
    @report_data = generate_inboxes_report

    respond_to do |format|
      format.csv  { generate_csv('inboxes_report', 'api/v2/accounts/reports/inboxes') }
      format.xlsx { generate_xlsx('inboxes_report', 'api/v2/accounts/reports/inboxes') }
      format.any  { generate_csv('inboxes_report', 'api/v2/accounts/reports/inboxes') }
    end
  end

  def labels
    @report_data = generate_labels_report

    respond_to do |format|
      format.csv  { generate_csv('labels_report', 'api/v2/accounts/reports/labels') }
      format.xlsx { generate_xlsx('labels_report', 'api/v2/accounts/reports/labels') }
      format.any  { generate_csv('labels_report', 'api/v2/accounts/reports/labels') }
    end
  end

  def teams
    @report_data = generate_teams_report

    respond_to do |format|
      format.csv  { generate_csv('teams_report', 'api/v2/accounts/reports/teams') }
      format.xlsx { generate_xlsx('teams_report', 'api/v2/accounts/reports/teams') }
      format.any  { generate_csv('teams_report', 'api/v2/accounts/reports/teams') }
    end
  end

  def conversations_summary
    @report_data = generate_conversations_report

    respond_to do |format|
      format.csv  { generate_csv('conversations_summary_report', 'api/v2/accounts/reports/conversations_summary') }
      format.xlsx { generate_xlsx('conversations_summary_report', 'api/v2/accounts/reports/conversations_summary') }
      format.any  { generate_csv('conversations_summary_report', 'api/v2/accounts/reports/conversations_summary') }
    end
  end

  def conversation_traffic
    @report_data = generate_conversations_heatmap_report
    timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone[timezone_offset]

    respond_to do |format|
      format.csv  { generate_csv('conversation_traffic_reports', 'api/v2/accounts/reports/conversation_traffic') }
      format.xlsx { generate_xlsx('conversation_traffic_reports', 'api/v2/accounts/reports/conversation_traffic') }
      format.any  { generate_csv('conversation_traffic_reports', 'api/v2/accounts/reports/conversation_traffic') }
    end
  end

  def conversations
    return head :unprocessable_entity if params[:type].blank?

    render json: conversation_metrics
  end

  def bot_metrics
    bot_metrics = V2::Reports::BotMetricsBuilder.new(Current.account, bot_metrics_params).metrics
    render json: bot_metrics
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

  def handle_email_delivery(filter_params)
    recipient_email = params[:email].presence || current_user.email

    Reports::AllMetricsJob.perform_later(Current.account.id,  current_user.id,
                                         filter_params.merge(format: params[:format] || 'csv', email: recipient_email))

    render json: { message: I18n.t('reports.email_delivery.queued'), status: 'queued', email: recipient_email }, status: :accepted
  end

  def valid_agent_activity_params?
    return true if params[:since].presence&.to_i && params[:until].presence&.to_i

    render json: { error: 'since and until are required' }, status: :unprocessable_entity
    false
  end

  def build_agent_activity_data
    since = params[:since].to_i
    until_ = params[:until].to_i

    builder = V2::Reports::AgentActivityBuilder.new(Current.account, agent_activity_params)

    @since = Time.zone.at(since)
    @until = Time.zone.at(until_)
    @agents = builder.call
  end

  def agent_activity_params
    params.permit(:since, :until, :timezone_offset, :hide_inactive, team_ids: [], user_ids: [], inbox_ids: [])
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

  def all_conversation_metrics_params
    { since: params[:since],  until: params[:until], timezone_offset: params[:timezone_offset],
      business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours]) }
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

  def generate_csv(filename, template)
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"
    render layout: false, template: template, formats: [:csv]
  end

  def generate_xlsx(filename, template)
    response.headers['Content-Type'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.xlsx"
    render layout: false, template: template, formats: [:xlsx]
  end

  def check_authorization
    authorize :report, :view?
  end

  def with_params(temp_params)
    original_params = params
    self.params = temp_params
    yield
  ensure
    self.params = original_params
  end

  def overview_summary_params
    { type: :account, since: params[:since], until: params[:until], timezone_offset: params[:timezone_offset],
      business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours]) }
  end

  def common_params
    { type: params[:type].to_sym,  id: params[:id], group_by: params[:group_by],
      business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours]) }
  end

  def current_summary_params
    common_params.merge({ since: range[:current][:since], until: range[:current][:until], timezone_offset: params[:timezone_offset],
                          inbox_ids: params[:inbox_ids]&.reject(&:blank?) })
  end

  def previous_summary_params
    common_params.merge({ since: range[:previous][:since], until: range[:previous][:until], timezone_offset: params[:timezone_offset],
                          inbox_ids: params[:inbox_ids]&.reject(&:blank?) })
  end

  def report_params
    common_params.merge({ metric: params[:metric], since: params[:since],  until: params[:until], timezone_offset: params[:timezone_offset],
                          inbox_ids: params[:inbox_ids]&.reject(&:blank?) })
  end

  def conversation_params
    { type: params[:type].to_sym, user_id: params[:user_id], page: params[:page].presence || 1 }
  end

  def range
    { current: { since: params[:since], until: params[:until] },
      previous: { since: (params[:since].to_i - (params[:until].to_i - params[:since].to_i)).to_s, until: params[:since] }  }
  end

  def build_summary(method)
    builder = V2::Reports::Conversations::MetricBuilder
    current_summary = builder.new(Current.account, current_summary_params).send(method)
    previous_summary = builder.new(Current.account, previous_summary_params).send(method)
    current_summary.merge(previous: previous_summary)
  end

  def conversation_metrics
    V2::ReportBuilder.new(Current.account, conversation_params).conversation_metrics
  end
end
