class Api::V2::Accounts::SummaryReportsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :prepare_builder_params, only: [:agent, :team, :inbox, :label, :channel, :bot]

  def agent
    render_report_with(V2::Reports::AgentSummaryBuilder, type: :agent)
  end

  def team
    render_report_with(V2::Reports::TeamSummaryBuilder, type: :team)
  end

  def inbox
    render_report_with(V2::Reports::InboxSummaryBuilder, type: :inbox)
  end

  def label
    render_report_with(V2::Reports::LabelSummaryBuilder)
  end

  def bot
    render_report_with(V2::Reports::BotSummaryReportBuilder)
  end

  def channel
    return render_could_not_create_error(I18n.t('errors.reports.date_range_too_long')) if date_range_too_long?

    render_report_with(V2::Reports::ChannelSummaryBuilder)
  end

  def agent_activity
    builder = V2::Reports::AgentActivityBuilder.new(
      Current.account,
      agent_activity_params
    )

    render json: builder.call
  end

  private

  def check_authorization
    authorize({ action: action_name, type: params[:type] }, :view?, policy_class: ReportPolicy)
  end

  def agent_activity_params
    params.permit(
      :since,
      :until,
      :timezone_offset,
      :hide_inactive,
      user_ids: [],
      team_ids: [],
      inbox_ids: []
    )
  end

  def prepare_builder_params
    @builder_params = {
      since: permitted_params[:since],
      until: permitted_params[:until],
      business_hours: ActiveModel::Type::Boolean.new.cast(permitted_params[:business_hours]),
      inbox_ids: permitted_params[:inbox_ids],
      user_ids: permitted_params[:user_ids],
      team_ids: permitted_params[:team_ids],
      label_ids: permitted_params[:label_ids]
    }.compact
  end

  def render_report_with(builder_class, type: nil)
    builder_params = type.present? ? @builder_params.merge(type: type) : @builder_params
    builder = builder_class.new(account: Current.account, params: builder_params)
    render json: builder.build
  end

  def permitted_params
    params.permit(:since, :until, :business_hours, inbox_ids: [], user_ids: [], team_ids: [], label_ids: [])
  end

  def date_range_too_long?
    return false if permitted_params[:since].blank? || permitted_params[:until].blank?

    since_time = Time.zone.at(permitted_params[:since].to_i)
    until_time = Time.zone.at(permitted_params[:until].to_i)
    (until_time - since_time) > 6.months
  end
end
