class V2::Reports::AgentActivityBuilder
  attr_reader :account, :params

  def initialize(account, params)
    @account = account
    @params = params
    @timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone[@timezone_offset]&.name || 'UTC'
  end

  def call
    agents_data = []

    users_scope.find_each do |user|
      agent_data = build_agent_data(user)
      agents_data << agent_data if (agent_data[:total_duration]).positive? || !hide_inactive?
    end

    agents_data.sort_by { |a| -a[:total_duration] }
  end

  private

  def users_scope
    scope = base_users_scope
    scope = filter_by_users(scope)
    scope = filter_by_teams(scope)
    scope = filter_by_inboxes(scope)

    scope.group('users.id')
  end

  def base_users_scope
    account.users
           .joins(:account_users)
           .where(account_users: { account_id: account.id })
  end

  def filter_by_users(scope)
    return scope if params[:user_ids].blank?

    scope.where(id: params[:user_ids])
  end

  def filter_by_teams(scope)
    return scope if params[:team_ids].blank?

    scope.joins(:teams)
         .where(teams: { id: params[:team_ids] })
  end

  def filter_by_inboxes(scope)
    return scope if params[:inbox_ids].blank?

    scope.joins(:inboxes)
         .where(inboxes: { id: params[:inbox_ids] })
  end

  def build_agent_data(user)
    logs = activity_logs_for_user(user.id)
    timeline = build_timeline(logs)

    {
      id: user.id,
      name: user.name,
      email: user.email,
      avatar_url: user.avatar_url,
      total_duration: calculate_total_active_duration(logs),
      online_duration: calculate_duration_by_status(logs, 'online'),
      busy_duration: calculate_duration_by_status(logs, 'busy'),
      offline_duration: calculate_offline_duration(logs),
      timeline: timeline,
      current_status: current_status(user.id)
    }
  end

  def activity_logs_for_user(user_id)
    logs = AgentActivityLog
           .where(account_id: account.id, user_id: user_id)
           .in_period(period_start, period_end)
           .order(:started_at)

    logs.map do |log|
      log.ended_at = [Time.zone.now, period_end].min if log.ended_at.nil?
      log
    end
  end

  def build_timeline(logs)
    timeline = []

    logs.each do |log|
      start_time = [log.started_at, period_start].max
      end_time = [log.ended_at || Time.zone.now, period_end].min

      timeline << {
        status: log.status,
        started_at: start_time.in_time_zone(@timezone).iso8601,
        ended_at: end_time.in_time_zone(@timezone).iso8601,
        duration: (end_time - start_time).to_i
      }
    end

    timeline
  end

  def calculate_total_active_duration(logs)
    logs.select(&:active?).sum do |log|
      calculate_log_duration_in_period(log)
    end
  end

  def calculate_duration_by_status(logs, status)
    logs.select { |log| log.status == status }.sum do |log|
      calculate_log_duration_in_period(log)
    end
  end

  def calculate_offline_duration(logs)
    total_period = period_end - period_start
    active_duration = calculate_total_active_duration(logs)
    (total_period - active_duration).to_i
  end

  def calculate_log_duration_in_period(log)
    start_time = [log.started_at, period_start].max
    end_time = [log.ended_at || Time.zone.now, period_end].min

    return 0 if end_time <= start_time

    (end_time - start_time).to_i
  end

  def current_status(user_id)
    redis_status = OnlineStatusTracker.get_status(account.id, user_id)
    is_present = OnlineStatusTracker.get_presence(account.id, 'User', user_id)

    return 'offline' unless is_present

    redis_status || 'online'
  end

  def period_start
    @period_start ||= Time.zone.at(params[:since].to_i).in_time_zone(@timezone)
  end

  def period_end
    @period_end ||= Time.zone.at(params[:until].to_i).in_time_zone(@timezone)
  end

  def hide_inactive?
    ActiveModel::Type::Boolean.new.cast(params[:hide_inactive])
  end
end
