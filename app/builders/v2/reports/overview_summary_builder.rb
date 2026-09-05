class V2::Reports::OverviewSummaryBuilder
  attr_reader :account, :params

  def initialize(account, params = {})
    @account = account
    @params = params
    @timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone['UTC']
  end

  def build
    {
      conversation_metrics: conversation_metrics,
      agent_status: agent_status,
      summary: summary,
      date_range: date_range
    }
  end

  private

  def conversation_metrics
    scope = load_conversations

    {
      open: scope.open.count,
      unattended: scope.open.unattended.count,
      unassigned: scope.open.unassigned.count,
      pending: scope.pending.count,
      resolved: scope.resolved.count
    }
  end

  def load_conversations
    scope = account.conversations
    scope = apply_team_filter(scope)
    scope = apply_user_filter(scope)
    scope = apply_inbox_filter(scope)
    apply_date_filter(scope)
  end

  def apply_team_filter(scope)
    team_ids.present? ? scope.where(team_id: team_ids) : scope
  end

  def apply_user_filter(scope)
    user_ids.present? ? scope.where(assignee_id: user_ids) : scope
  end

  def apply_inbox_filter(scope)
    inbox_ids.present? ? scope.where(inbox_id: inbox_ids) : scope
  end

  def apply_date_filter(scope)
    return scope unless params[:since].present? && params[:until].present?

    since = Time.at(params[:since].to_i).utc
    until_time = Time.at(params[:until].to_i).utc
    scope.where(created_at: since..until_time)
  end

  def team_ids
    return [] if params[:team_ids].blank?

    params[:team_ids].reject(&:blank?)
  end

  def user_ids
    return [] if params[:user_ids].blank?

    params[:user_ids].reject(&:blank?)
  end

  def inbox_ids
    return [] if params[:inbox_ids].blank?

    params[:inbox_ids].reject(&:blank?)
  end

  def agent_status
    agents = account.account_users
    agents = filter_agents_by_users(agents)
    agents = filter_agents_by_teams(agents)
    agents.filter_map(&:availability_status).tally
  end

  def filter_agents_by_users(agents)
    user_ids.present? ? agents.where(user_id: user_ids) : agents
  end

  def filter_agents_by_teams(agents)
    return agents if team_ids.blank?

    user_ids_in_teams = account.users
                               .joins(:team_members)
                               .where(team_members: { team_id: team_ids })
                               .pluck(:id)

    agents.where(user_id: user_ids_in_teams)
  end

  def summary
    V2::Reports::Conversations::MetricBuilder
      .new(account, summary_params)
      .summary
  end

  def summary_params
    base_summary_params.merge(optional_filter_params).merge(optional_time_params)
  end

  def base_summary_params
    {
      type: :account,
      since: since_timestamp,
      until: until_timestamp,
      business_hours: params[:business_hours] || false
    }
  end

  def optional_filter_params
    {}.tap do |opts|
      opts[:user_ids] = params[:user_ids] if params[:user_ids].present?
      opts[:inbox_ids] = params[:inbox_ids] if params[:inbox_ids].present?
      opts[:team_ids] = params[:team_ids] if params[:team_ids].present?
    end
  end

  def optional_time_params
    {}.tap do |opts|
      opts[:time_since] = params[:time_since] if params[:time_since].present?
      opts[:time_until] = params[:time_until] if params[:time_until].present?
    end
  end

  def date_range
    {
      since: Time.at(since_timestamp.to_i).in_time_zone(@timezone),
      until: Time.at(until_timestamp.to_i).in_time_zone(@timezone)
    }
  end

  def since_timestamp
    params[:since]
  end

  def until_timestamp
    params[:until]
  end
end
