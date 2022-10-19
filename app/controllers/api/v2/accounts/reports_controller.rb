class Api::V2::Accounts::ReportsController < Api::V1::Accounts::BaseController
  include Api::V2::Accounts::ReportsHelper
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
    @report_data = generate_agents_report
    generate_csv('agents_report', 'api/v2/accounts/reports/agents')
  end

  def inboxes
    @report_data = generate_inboxes_report
    generate_csv('inboxes_report', 'api/v2/accounts/reports/inboxes')
  end

  def labels
    @report_data = generate_labels_report
    generate_csv('labels_report', 'api/v2/accounts/reports/labels')
  end

  def teams
    @report_data = generate_teams_report
    generate_csv('teams_report', 'api/v2/accounts/reports/teams')
  end

  def conversations
    return head :unprocessable_entity if params[:type].blank?

    render json: conversation_metrics
  end

  private

  def generate_csv(filename, template)
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"
    render layout: false, template: template, formats: [:csv]
  end

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
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
    common_params.merge({
                          since: range[:current][:since],
                          until: range[:current][:until]
                        })
  end

  def previous_summary_params
    common_params.merge({
                          since: range[:previous][:since],
                          until: range[:previous][:until]
                        })
  end

  def report_params
    common_params.merge({
                          metric: params[:metric],
                          since: params[:since],
                          until: params[:until],
                          timezone_offset: params[:timezone_offset]
                        })
  end

  def conversation_params
    {
      type: params[:type].to_sym,
      user_id: params[:user_id],
      page: params[:page].presence || 1
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
