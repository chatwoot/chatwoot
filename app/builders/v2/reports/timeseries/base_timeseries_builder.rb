class V2::Reports::Timeseries::BaseTimeseriesBuilder
  include DateRangeHelper
  DEFAULT_GROUP_BY = 'day'.freeze

  pattr_initialize :account, :params

  def scope
    case params[:type]
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
    @group_by ||= params[:group_by] || DEFAULT_GROUP_BY
  end

  def timezone
    @timezone ||= ActiveSupport::TimeZone[timezone_offset]&.name
  end

  def timezone_offset
    @timezone_offset ||= params.fetch(:timezone_offset, 0).to_f
  end
end
