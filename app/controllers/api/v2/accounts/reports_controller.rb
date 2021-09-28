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

  private

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end

  def summary_params
    {
      type: params[:type].to_sym,
      since: params[:since],
      until: params[:until],
      id: params[:id]
    }
  end

  def report_params
    {
      metric: params[:metric],
      type: params[:type].to_sym,
      since: params[:since],
      until: params[:until],
      id: params[:id]
    }
  end

  def summary_metrics
    builder = V2::ReportBuilder.new(Current.account, summary_params)
    builder.summary
  end
end
