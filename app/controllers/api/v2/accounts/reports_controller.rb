class Api::V2::Accounts::ReportsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def account
    builder = V2::ReportBuilder.new(Current.account, account_report_params)
    data = builder.build
    render json: data
  end

  def account_summary
    render json: account_summary_metrics
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

  private

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end

  def account_summary_params
    {
      type: :account,
      since: params[:since],
      until: params[:until]
    }
  end

  def account_report_params
    {
      metric: params[:metric],
      type: :account,
      since: params[:since],
      until: params[:until]
    }
  end

  def account_summary_metrics
    builder = V2::ReportBuilder.new(Current.account, account_summary_params)
    builder.summary
  end
end
