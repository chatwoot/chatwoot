class Api::V2::Accounts::SummaryReportsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :prepare_builder_params, only: [:agent, :team]
  before_action :prepare_builder_template_params, only: [:template]

  def agent
    render_report_with(V2::Reports::AgentSummaryBuilder)
  end

  def team
    render_report_with(V2::Reports::TeamSummaryBuilder)
  end

  def template
    render_report_with(V2::Reports::Templates::MetricBuilder)
  end

  private

  def check_authorization
    authorize :report, :view?
  end

  def prepare_builder_params
    @builder_params = {
      since: permitted_params[:since],
      until: permitted_params[:until],
      business_hours: ActiveModel::Type::Boolean.new.cast(permitted_params[:business_hours])
    }
  end

  def prepare_builder_template_params
    @builder_params = {
      since: permitted_params[:since],
      until: permitted_params[:until],
      templateId: permitted_params[:templateId],
      channelId: permitted_params[:channelId],
      business_hours: ActiveModel::Type::Boolean.new.cast(permitted_params[:business_hours])
    }
  end

  def render_report_with(builder_class)
    builder = builder_class.new(account: Current.account, params: @builder_params)
    data = builder.build
    render json: data
  end

  def permitted_params
    params.permit(:since, :until, :business_hours, :templateId, :channelId)
  end
end
