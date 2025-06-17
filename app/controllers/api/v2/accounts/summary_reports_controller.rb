class Api::V2::Accounts::SummaryReportsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :prepare_builder_params, only: [:agent, :team, :inbox]

  def agent
    render_report_with(V2::Reports::AgentSummaryBuilder)
  end

  def team
    render_report_with(V2::Reports::TeamSummaryBuilder)
  end

  def inbox
    render_report_with(V2::Reports::InboxSummaryBuilder)
  end

  private

  def check_authorization
    return if Current.account.custom_attributes['show_reports_to_agent']

    authorize :report, :view?
  end

  def prepare_builder_params
    @builder_params = {
      since: permitted_params[:since],
      until: permitted_params[:until],
      business_hours: ActiveModel::Type::Boolean.new.cast(permitted_params[:business_hours])
    }
  end

  def render_report_with(builder_class)
    builder = builder_class.new(account: Current.account, params: @builder_params)
    data = builder.build
    render json: data
  end

  def permitted_params
    params.permit(:since, :until, :business_hours)
  end
end
