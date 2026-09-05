class V2::Reports::Timeseries::BaseTimeseriesBuilder
  include TimezoneHelper
  include DateRangeHelper

  DEFAULT_GROUP_BY = 'day'.freeze

  pattr_initialize :account, :params

  def scope
    case dimension_type.to_sym
    when :account
      account
    when :inbox
      inbox
    when :agent
      user
    when :label
      label
    when :team
      team
    end
  end

  def data_source
    @data_source ||= Reports::DataSource.for(
      account: account,
      metric: params[:metric],
      dimension_type: dimension_type,
      dimension_id: params[:id],
      scope: scope,
      range: range,
      group_by: group_by,
      timezone_offset: params[:timezone_offset],
      business_hours: params[:business_hours],
      inbox_ids: params[:inbox_ids],
      user_ids: params[:user_ids]
    )
  end

  def inbox
    @inbox ||= account.inboxes.find(params[:id])
  end

  def user
    @user ||= account.users.find(params[:id])
  end

  def label
    @label ||= account.labels.find(params[:id])
  end

  def team
    @team ||= account.teams.find(params[:id])
  end

  def group_by
    @group_by ||= %w[day week month year hour].include?(params[:group_by]) ? params[:group_by] : DEFAULT_GROUP_BY
  end

  def timezone
    'UTC'
  end

  private

  def apply_filters(relation)
    apply_user_filter(apply_inbox_filter(relation))
  end

  def apply_user_filter(relation)
    return relation if params[:user_ids].blank?
    return relation unless params[:type].to_sym == :account

    relation.where(assignee_id: params[:user_ids])
  end

  def apply_inbox_filter(relation)
    return relation if params[:inbox_ids].blank?
    return relation unless params[:type].to_sym == :account

    relation.where(inbox_id: params[:inbox_ids])
  end

  def apply_user_filter_via_conversation(relation)
    return relation if params[:user_ids].blank?
    return relation unless params[:type].to_sym == :account

    relation.joins(:conversation).where(conversations: { assignee_id: params[:user_ids] })
  end

  def dimension_type
    (params[:type].presence || 'account').to_s
  end
end
