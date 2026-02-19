class Api::V2::Accounts::ReportsController < Api::V1::Accounts::BaseController
  include Api::V2::Accounts::ReportsHelper
  include Api::V2::Accounts::HeatmapHelper
  include Api::V2::Accounts::ReportResponseFormatter

  before_action :check_authorization

  def index
    builder = V2::Reports::Conversations::ReportBuilder.new(Current.account, report_params)
    data = builder.timeseries
    render json: data
  end

  def all_conversation_metrics_download
    filter_params = report_service.send(:build_filter_params)

    if params[:send_email] == 'true'
      result = report_service.queue_email_delivery(filter_params)
      return render json: result, status: :accepted
    end

    @report_data = report_service.generate_all_conversation_metrics
    respond_with_report_download('all_conversation_metrics', 'api/v2/accounts/reports/all_conversation_metrics')
  end

  def summary
    render json: report_service.build_summary(:summary)
  end

  def bot_summary
    render json: report_service.build_summary(:bot_summary)
  end

  def agent_activity
    return render_missing_params_error unless valid_agent_activity_params?

    data = report_service.generate_agent_activity_data
    @since = data[:since]
    @until = data[:until]
    @agents = data[:agents]

    respond_with_report_download('agent_activity_report', 'api/v2/accounts/reports/agent_activity')
  end

  def bot_summary_download
    @report_data = generate_bots_report
    @date_range = report_service.format_date_range

    respond_with_report_download('bot_summary', 'api/v2/accounts/reports/bot_summary')
  end

  def overview_summary
    result = report_service.generate_overview_summary

    @conversation_metrics = result[:conversation_metrics]
    @agent_status         = result[:agent_status]
    @summary              = result[:summary]
    @date_range           = result[:date_range]

    respond_with_report_download('overview_summary', 'api/v2/accounts/reports/overview_summary')
  end

  def agents
    @report_data = generate_agents_report
    respond_with_report_download('agents_report', 'api/v2/accounts/reports/agents')
  end

  def inboxes
    @report_data = generate_inboxes_report
    respond_with_report_download('inboxes_report', 'api/v2/accounts/reports/inboxes')
  end

  def labels
    @report_data = generate_labels_report
    respond_with_report_download('labels_report', 'api/v2/accounts/reports/labels')
  end

  def teams
    @report_data = generate_teams_report
    respond_with_report_download('teams_report', 'api/v2/accounts/reports/teams')
  end

  def conversations_summary
    @report_data = generate_conversations_report
    respond_with_report_download('conversations_summary_report', 'api/v2/accounts/reports/conversations_summary')
  end

  def conversation_traffic
    @report_data = generate_conversations_heatmap_report
    timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone[timezone_offset]

    respond_with_report_download('conversation_traffic_reports', 'api/v2/accounts/reports/conversation_traffic')
  end

  def conversations
    return head :unprocessable_entity if params[:type].blank?

    render json: report_service.build_conversation_metrics
  end

  def bot_metrics
    render json: report_service.build_bot_metrics
  end

  private

  def valid_agent_activity_params?
    return true if params[:since].presence&.to_i && params[:until].presence&.to_i

    render json: { error: 'since and until are required' }, status: :unprocessable_entity
    false
  end

  def render_missing_params_error
    render json: { error: 'since and until are required' }, status: :unprocessable_entity
  end

  def report_params
    {
      type: params[:type].to_sym,
      id: params[:id],
      group_by: params[:group_by],
      business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours]),
      metric: params[:metric],
      since: params[:since],
      until: params[:until],
      timezone_offset: params[:timezone_offset],
      inbox_ids: params[:inbox_ids]&.reject(&:blank?)
    }
  end

  def check_authorization
    authorize :report, :view?
  end
end
