class Api::V2::Accounts::SummaryReportsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :prepare_builder_params, only: [:agent, :team, :inbox, :label, :channel]

  def agent
    render_report_with(V2::Reports::AgentSummaryBuilder, type: :agent, filters: { inbox_id: permitted_params[:inbox_id] })
  end

  def team
    render_report_with(V2::Reports::TeamSummaryBuilder, type: :team)
  end

  def inbox
    render_report_with(V2::Reports::InboxSummaryBuilder, type: :inbox, filters: { user_id: permitted_params[:user_id] })
  end

  def label
    render_report_with(V2::Reports::LabelSummaryBuilder)
  end

  # Distinct handled conversations over the whole range, for the account or the inbox
  # the agents report is narrowed to. Agents overlap on a conversation, so their rows
  # add up past it, and the distribution card needs the real total.
  def handled_conversations
    inbox_id = permitted_params[:inbox_id].presence
    builder = V2::Reports::Conversations::ReportBuilder.new(
      Current.account,
      { metric: Reports::HandledConversations::METRIC, type: inbox_id ? :inbox : :account, id: inbox_id,
        since: permitted_params[:since], until: permitted_params[:until] }
    )
    render json: { count: builder.aggregate_value }
  end

  def channel
    return render_could_not_create_error(I18n.t('errors.reports.date_range_too_long')) if date_range_too_long?

    render_report_with(V2::Reports::ChannelSummaryBuilder)
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

  def render_report_with(builder_class, type: nil, filters: {})
    builder_params = @builder_params.merge(filters.compact_blank)
    builder_params = builder_params.merge(type: type) if type.present?
    builder = builder_class.new(account: Current.account, params: builder_params)
    render json: builder.build
  end

  def permitted_params
    params.permit(:since, :until, :business_hours, :inbox_id, :user_id)
  end

  def date_range_too_long?
    return false if permitted_params[:since].blank? || permitted_params[:until].blank?

    since_time = Time.zone.at(permitted_params[:since].to_i)
    until_time = Time.zone.at(permitted_params[:until].to_i)
    (until_time - since_time) > 6.months
  end
end
