class Api::V2::Accounts::ReportsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    builder = V2::ReportBuilder.new(Current.account, report_params)
    data = builder.build
    render json: data
  end

  def summary
    render json: summary_metrics
  end

  def agents
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=agents_report.csv'
    render layout: false, template: 'api/v2/accounts/reports/agents.csv.erb', format: 'csv'
  end

  def inboxes
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=inboxes_report.csv'
    render layout: false, template: 'api/v2/accounts/reports/inboxes.csv.erb', format: 'csv'
  end

  def labels
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=labels_report.csv'
    render layout: false, template: 'api/v2/accounts/reports/labels.csv.erb', format: 'csv'
  end

  def teams
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=teams_report.csv'
    render layout: false, template: 'api/v2/accounts/reports/teams.csv.erb', format: 'csv'
  end

  def conversations
    return head :unprocessable_entity if params[:type].blank?

    render json: conversation_metrics
  end

  private

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end

  def current_summary_params
    {
      type: params[:type].to_sym,
      id: params[:id],
      since: range[:current][:since],
      until: range[:current][:until],
      group_by: params[:group_by]
    }
  end

  def previous_summary_params
    {
      type: params[:type].to_sym,
      id: params[:id],
      since: range[:previous][:since],
      until: range[:previous][:until],
      group_by: params[:group_by]
    }
  end

  def report_params
    {
      metric: params[:metric],
      type: params[:type].to_sym,
      since: params[:since],
      until: params[:until],
      id: params[:id],
      group_by: params[:group_by],
      timezone_offset: params[:timezone_offset]
    }
  end

  def conversation_params
    {
      type: params[:type].to_sym,
      user_id: params[:user_id]
    }
  end

  def range
    {
      current: {
        since: params[:since],
        until: params[:until]
      },
      previous: {
        since: (params[:since].to_i - (params[:until].to_i - params[:since].to_i)).to_s,
        until: params[:since]
      }
    }
  end

  def summary_metrics
    summary = V2::ReportBuilder.new(Current.account, current_summary_params).summary
    summary[:previous] = V2::ReportBuilder.new(Current.account, previous_summary_params).summary
    summary
  end

  def conversation_metrics
    V2::ReportBuilder.new(Current.account, conversation_params).conversation_metrics
  end
end
