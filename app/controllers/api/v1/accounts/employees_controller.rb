# rubocop:disable Metrics/ClassLength
class Api::V1::Accounts::EmployeesController < Api::V1::Accounts::BaseController
  IDLE_AFTER_MINUTES = 15
  NOT_RESPONDING_AFTER_MINUTES = 10
  DAILY_REPORT_TIME_ZONE = 'Africa/Cairo'.freeze
  ACTIVITY_REPORTING_EVENTS = %w[first_response reply_time conversation_resolved conversation_opened].freeze

  before_action :check_admin_authorization?
  before_action :fetch_employee, except: [:index, :create, :bulk_update]
  before_action :validate_limit, only: [:create]

  def index
    @employees = filtered_employees.includes(:teams, :inboxes, :employee_sessions, :employee_login_events, :account_users).order_by_full_name
    @employee_metrics = build_employee_metrics(@employees)
    @employees = filter_by_activity_metrics(@employees.to_a)
  end

  def show
    @employee_metrics = build_employee_metrics([@employee])
  end

  def create
    return render_employee_management_error(:inbox_required) if permitted_inbox_ids.blank?

    ActiveRecord::Base.transaction do
      @employee = User.create!(user_attributes.merge(local_auth_enabled: true, confirmed_at: Time.current))
      @employee_account_user = Current.account.account_users.create!(account_user_attributes.merge(user: @employee, inviter: current_user))
      sync_teams!
      sync_inboxes!
      audit_employee_event(@employee, 'employee_create')
    end
  end

  def update
    return if disabling_admin_access? && !can_manage_employee?
    return render_employee_management_error(:inbox_required) if permitted_params.key?(:inbox_ids) && permitted_inbox_ids.blank?

    ActiveRecord::Base.transaction do
      attrs = user_attributes.merge(local_auth_enabled: true).compact
      # Only include password if explicitly provided
      attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?
      @employee.update!(attrs)
      employee_account_user.update!(account_user_attributes.except(:active, :deactivation_reason).compact)
      sync_teams!
      sync_inboxes!
      audit_employee_event(@employee, 'employee_update')
    end
  end

  def change_password
    @employee.update!(password_params)
    @employee.invalidate_all_employee_sessions!
    audit_employee_event(@employee, 'employee_password_change')
    head :ok
  end

  def activate
    employee_account_user.update!(active: true, archived_at: nil, deactivation_reason: nil)
    @employee.reset_failed_login_attempts!
    audit_employee_event(@employee, 'employee_activate')
    render :show
  end

  def deactivate
    return unless can_manage_employee?

    employee_account_user.update!(active: false, deactivation_reason: permitted_params[:deactivation_reason])
    @employee.invalidate_all_employee_sessions!
    audit_employee_event(@employee, 'employee_deactivate', deactivation_reason: permitted_params[:deactivation_reason])
    render :show
  end

  def archive
    return unless can_manage_employee?

    employee_account_user.update!(active: false, archived_at: Time.current, deactivation_reason: permitted_params[:deactivation_reason])
    @employee.invalidate_all_employee_sessions!
    audit_employee_event(@employee, 'employee_archive', deactivation_reason: permitted_params[:deactivation_reason])
    render :show
  end

  def destroy
    return unless can_manage_employee?

    employee_account_user.destroy!
    @employee.invalidate_all_employee_sessions!
    DeleteObjectJob.perform_later(@employee) if @employee.reload.account_users.blank?
    audit_employee_event(@employee, 'employee_delete')
    head :ok
  end

  def sessions
    @employee_sessions = @employee.employee_sessions.recent
  end

  def destroy_session
    client_id = params[:client_id].to_s
    @employee.tokens&.delete(client_id)
    @employee.save!
    sign_out_employee_sessions(@employee.employee_sessions.where(client_id: client_id))
    audit_employee_event(@employee, 'employee_session_logout', client_id: client_id)
    head :ok
  end

  def force_logout
    @employee.invalidate_all_employee_sessions!
    audit_employee_event(@employee, 'employee_force_logout')
    head :ok
  end

  def login_history
    @login_events = @employee.employee_login_events.where(account: Current.account).recent.limit(100)
  end

  def activity
    @employee_metrics = build_employee_metrics([@employee])
    @employee_activity = build_employee_activity(@employee, @employee_metrics[@employee.id])
  end

  def bulk_update
    users = Current.account.users.where(id: params[:user_ids])
    users.each do |user|
      @employee = user
      @employee_account_user = nil
      apply_bulk_action(user)
    end
    head :ok
  end

  private

  def fetch_employee
    @employee = Current.account.users.find(params[:id])
  end

  def employee_account_user
    @employee_account_user ||= Current.account.account_users.find_by!(user_id: @employee.id)
  end

  def filtered_employees
    employees = Current.account.users
    employees = employees.where(local_auth_enabled: true) if params[:local_only].blank? || ActiveModel::Type::Boolean.new.cast(params[:local_only])
    employees = filter_by_search(employees)
    employees = filter_by_role(employees)
    employees = filter_by_team(employees)
    employees = filter_by_status(employees)
    employees = filter_by_last_login(employees)
    filter_by_last_activity(employees)
  end

  def filter_by_search(employees)
    return employees if params[:q].blank?

    query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.downcase)}%"
    employees.where(
      [
        'lower(users.name) LIKE :query',
        'lower(users.username) LIKE :query',
        'users.phone_number LIKE :query'
      ].join(' OR '),
      query: query
    )
  end

  def apply_bulk_action(user)
    case params[:action_type]
    when 'activate'
      employee_account_user.update!(active: true, archived_at: nil, deactivation_reason: nil)
    when 'deactivate'
      return unless can_manage_employee?

      employee_account_user.update!(active: false, deactivation_reason: params[:deactivation_reason])
      user.invalidate_all_employee_sessions!
    when 'archive'
      return unless can_manage_employee?

      employee_account_user.update!(active: false, archived_at: Time.current, deactivation_reason: params[:deactivation_reason])
      user.invalidate_all_employee_sessions!
    end
    audit_employee_event(user, "employee_bulk_#{params[:action_type]}")
  end

  def filter_by_role(employees)
    return employees if params[:role].blank?

    employees.where(account_users: { account_id: Current.account.id, role: AccountUser.roles[params[:role]] })
  end

  def filter_by_team(employees)
    return employees if params[:team_id].blank?

    employees.joins(:team_members).where(team_members: { team_id: params[:team_id] })
  end

  def filter_by_status(employees)
    case params[:status]
    when 'active'
      employees.where(account_users: { account_id: Current.account.id, active: true, archived_at: nil })
    when 'inactive'
      employees.where(account_users: { account_id: Current.account.id, active: false, archived_at: nil })
    when 'archived'
      employees.where(account_users: { account_id: Current.account.id }).where.not(account_users: { archived_at: nil })
    else
      employees.where(account_users: { account_id: Current.account.id })
    end
  end

  def filter_by_last_login(employees)
    case params[:last_login]
    when 'never'
      employees.where(current_sign_in_at: nil, last_sign_in_at: nil)
    when '7_days'
      employees.where('COALESCE(users.current_sign_in_at, users.last_sign_in_at) >= ?', 7.days.ago)
    when '30_days'
      employees.where('COALESCE(users.current_sign_in_at, users.last_sign_in_at) >= ?', 30.days.ago)
    else
      employees
    end
  end

  def filter_by_last_activity(employees)
    case params[:last_activity]
    when 'never'
      employees.where(account_users: { account_id: Current.account.id, active_at: nil })
    when '7_days'
      employees.where(account_users: { account_id: Current.account.id }).where('account_users.active_at >= ?', 7.days.ago)
    when '30_days'
      employees.where(account_users: { account_id: Current.account.id }).where('account_users.active_at >= ?', 30.days.ago)
    else
      employees
    end
  end

  def user_attributes
    attributes = permitted_params.slice(:name, :email, :username, :phone_number, :password, :password_confirmation).compact
    attributes[:email] = generated_employee_email(attributes[:username]) if @employee.blank? && attributes[:email].blank?
    attributes
  end

  def account_user_attributes
    permitted_params.slice(:role, :job_title, :employee_notes, :active, :deactivation_reason).compact.reject { |_key, value| value == '' }
  end

  def password_params
    params.require(:employee).permit(:password, :password_confirmation)
  end

  def permitted_params
    params.require(:employee).permit(
      :name, :email, :username, :phone_number, :role, :job_title, :employee_notes, :active, :deactivation_reason,
      :password, :password_confirmation, team_ids: [], inbox_ids: []
    )
  end

  def generated_employee_email(username)
    "#{username.to_s.strip.downcase}@local.chatwoot"
  end

  def sync_teams!
    return unless permitted_params.key?(:team_ids)

    team_ids = Current.account.teams.where(id: permitted_params[:team_ids]).pluck(:id)
    current_team_ids = @employee.team_members.joins(:team).where(teams: { account_id: Current.account.id }).pluck(:team_id)

    (team_ids - current_team_ids).each { |team_id| TeamMember.create!(team_id: team_id, user: @employee) }
    @employee.team_members.where(team_id: current_team_ids - team_ids).destroy_all
  end

  def sync_inboxes!
    return unless permitted_params.key?(:inbox_ids)

    inbox_ids = permitted_inbox_ids
    current_inbox_ids = current_employee_inbox_ids

    add_employee_to_inboxes(inbox_ids - current_inbox_ids)
    remove_employee_from_inboxes(current_inbox_ids - inbox_ids)
  end

  def permitted_inbox_ids
    Current.account.inboxes.where(id: permitted_params[:inbox_ids]).pluck(:id)
  end

  def current_employee_inbox_ids
    @employee.inbox_members
             .joins(:inbox)
             .where(inboxes: { account_id: Current.account.id })
             .pluck(:inbox_id)
  end

  def add_employee_to_inboxes(inbox_ids)
    Current.account.inboxes.where(id: inbox_ids).find_each { |inbox| inbox.add_members([@employee.id]) }
  end

  def remove_employee_from_inboxes(inbox_ids)
    Current.account.inboxes.where(id: inbox_ids).find_each { |inbox| inbox.remove_members([@employee.id]) }
  end

  def disabling_admin_access?
    employee_account_user.administrator? && account_user_attributes[:role] == 'agent'
  end

  def can_manage_employee?
    return render_employee_management_error(:cannot_manage_self) if @employee.id == current_user.id

    return true unless employee_account_user.administrator?
    return true if Current.account.account_users.active_employees.administrator.where.not(user_id: @employee.id).exists?

    render_employee_management_error(:cannot_disable_last_admin)
  end

  def render_employee_management_error(error_key)
    render_could_not_create_error(I18n.t("errors.employees.#{error_key}"))
    false
  end

  def validate_limit
    render_payment_required('Account limit exceeded. Please purchase more licenses') unless can_add_agent?
  end

  def can_add_agent?
    Current.account.usage_limits[:agents] - Current.account.users.count >= 1
  end

  def audit_employee_event(employee, action, changes = {})
    return unless employee.respond_to?(:audits)

    employee.audits.create(
      action: action,
      user_id: current_user.id,
      associated_id: Current.account.id,
      associated_type: 'Account',
      audited_changes: changes.merge(user_id: employee.id)
    )
  end

  def sign_out_employee_sessions(sessions)
    sessions.open.find_each { |employee_session| employee_session.update!(signed_out_at: Time.current) }
  end

  # These methods aggregate live monitoring data from several Chatwoot reporting tables.
  # Keeping them together makes the state-priority rules easier to audit.
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def build_employee_metrics(employees)
    employee_ids = employees.map(&:id)
    return {} if employee_ids.blank?

    account_users = Current.account.account_users.where(user_id: employee_ids).index_by(&:user_id)
    open_conversations = Current.account.conversations.open.where(assignee_id: employee_ids)
    assigned_conversations = Current.account.conversations.where(assignee_id: employee_ids).where.not(status: :resolved)
    replies = human_agent_replies(employee_ids)
    reporting_events = Current.account.reporting_events.where(user_id: employee_ids)
    today = Time.zone.now.all_day

    open_counts = open_conversations.group(:assignee_id).count
    assigned_counts = assigned_conversations.group(:assignee_id).count
    unreplied_counts = open_conversations.where.not(waiting_since: nil).group(:assignee_id).count
    delayed_counts = open_conversations.where(waiting_since: ..not_responding_threshold).group(:assignee_id).count
    oldest_waiting = open_conversations.where.not(waiting_since: nil).group(:assignee_id).minimum(:waiting_since)
    last_reply = replies.group(:sender_id).maximum(:created_at)
    replies_today = replies.where(created_at: today).group(:sender_id).count
    latest_reporting_activity = reporting_events.where(name: ACTIVITY_REPORTING_EVENTS).group(:user_id).maximum(:created_at)
    resolved_today = reporting_events.where(name: 'conversation_resolved', created_at: today).group(:user_id).count
    first_response_average = average_reporting_event(reporting_events, 'first_response', today)
    response_average = average_reporting_event(reporting_events, 'reply_time', today)
    resolution_average = average_reporting_event(reporting_events, 'conversation_resolved', today)

    employee_ids.index_with do |employee_id|
      account_user = account_users[employee_id]
      last_activity_at = [last_reply[employee_id], latest_reporting_activity[employee_id]].compact.max
      presence_status = presence_status_for(employee_id, account_user)
      work_status = work_status_for(account_user, presence_status, delayed_counts[employee_id].to_i, last_activity_at)

      {
        account_status: account_status_for(account_user),
        presence_status: presence_status,
        work_status: work_status,
        last_seen_at: account_user&.active_at,
        last_activity_at: last_activity_at,
        last_reply_at: last_reply[employee_id],
        time_since_last_reply: seconds_since(last_reply[employee_id]),
        idle_duration: presence_status == 'online' ? seconds_since(last_activity_at) : nil,
        assigned_conversations_count: assigned_counts[employee_id].to_i,
        open_conversations_count: open_counts[employee_id].to_i,
        unreplied_conversations_count: unreplied_counts[employee_id].to_i,
        delayed_unreplied_conversations_count: delayed_counts[employee_id].to_i,
        oldest_waiting_customer_at: oldest_waiting[employee_id],
        oldest_waiting_customer_seconds: seconds_since(oldest_waiting[employee_id]),
        replies_count_today: replies_today[employee_id].to_i,
        resolved_conversations_today: resolved_today[employee_id].to_i,
        first_response_average_today: first_response_average[employee_id].to_f,
        average_response_time_today: response_average[employee_id].to_f,
        average_resolution_time_today: resolution_average[employee_id].to_f
      }
    end
  end

  def build_employee_activity(employee, metrics)
    threshold = not_responding_threshold
    open_conversations = Current.account.conversations.open.where(assignee_id: employee.id).order(waiting_since: :asc, updated_at: :desc)
    replies = human_agent_replies([employee.id]).includes(:conversation).order(created_at: :desc).limit(10)
    resolved_events = Current.account.reporting_events.where(user_id: employee.id, name: 'conversation_resolved')
                             .includes(:conversation).order(created_at: :desc).limit(10)

    {
      metrics: metrics,
      daily_performance: build_employee_daily_performance(employee, metrics),
      recent_replies: replies.map { |message| activity_message_payload(message) },
      open_conversations: open_conversations.limit(10).map { |conversation| activity_conversation_payload(conversation) },
      delayed_conversations: open_conversations.where(waiting_since: ..threshold).limit(10).map do |conversation|
        activity_conversation_payload(conversation)
      end,
      resolved_conversations: resolved_events.map { |event| activity_reporting_event_payload(event) },
      timeline: activity_timeline(employee, replies, resolved_events, metrics)
    }
  end

  def filter_by_activity_metrics(employees)
    employees.select do |employee|
      metrics = @employee_metrics[employee.id] || {}
      next false if params[:presence_status].present? && metrics[:presence_status] != params[:presence_status]
      next false if params[:work_status].present? && metrics[:work_status] != params[:work_status]
      next false if truthy_param?(:has_open_conversations) && metrics[:open_conversations_count].to_i.zero?
      next false if truthy_param?(:has_unreplied_conversations) && metrics[:unreplied_conversations_count].to_i.zero?
      next false if truthy_param?(:has_resolved_today) && metrics[:resolved_conversations_today].to_i.zero?
      next false if params[:idle_more_than].present? && metrics[:idle_duration].to_i < params[:idle_more_than].to_i * 60
      next false if params[:last_reply_before].present? && !older_than_minutes?(metrics[:last_reply_at], params[:last_reply_before])
      next false if params[:last_activity_before].present? && !older_than_minutes?(metrics[:last_activity_at], params[:last_activity_before])

      true
    end
  end

  def human_agent_replies(employee_ids)
    Current.account.messages.reorder(nil).where(
      message_type: :outgoing,
      private: false,
      sender_type: 'User',
      sender_id: employee_ids
    )
  end

  def average_reporting_event(reporting_events, name, range)
    reporting_events.where(name: name, created_at: range).group(:user_id).average(:value)
  end

  def build_employee_daily_performance(employee, metrics)
    today = daily_report_range
    replies_today = human_agent_replies([employee.id]).where(created_at: today)
    response_times = daily_response_times(employee, replies_today, today)
    first_login_at = first_login_today(employee, today)
    last_reply_at = replies_today.maximum(:created_at)
    reporting_events = Current.account.reporting_events
    latest_reporting_activity = reporting_events.where(user_id: employee.id, name: ACTIVITY_REPORTING_EVENTS, created_at: today).maximum(:created_at)
    last_seen_today = metrics[:last_seen_at] if metrics[:last_seen_at].present? && today.cover?(metrics[:last_seen_at])
    last_activity_at = [last_reply_at, latest_reporting_activity, last_seen_today].compact.max

    {
      date: today.begin.to_date,
      time_zone: DAILY_REPORT_TIME_ZONE,
      first_login_at: first_login_at,
      last_seen_at: metrics[:last_seen_at],
      last_activity_at: last_activity_at,
      last_reply_at: last_reply_at,
      messages_count: replies_today.count,
      customers_replied_count: customers_replied_today_count(replies_today),
      average_response_seconds: average_seconds(response_times),
      fastest_response_seconds: response_times.min,
      slowest_response_seconds: response_times.max,
      idle_duration: seconds_since(last_activity_at)
    }
  end

  def daily_report_range
    Time.use_zone(DAILY_REPORT_TIME_ZONE) { Time.zone.now.all_day }
  end

  def first_login_today(employee, range)
    login_at = employee.employee_login_events.where(account: Current.account, success: true, created_at: range).minimum(:created_at)
    session_at = employee.employee_sessions.where(signed_in_at: range).minimum(:signed_in_at)
    [login_at, session_at].compact.min
  end

  def customers_replied_today_count(replies)
    replies.joins(:conversation).distinct.count('conversations.contact_id')
  end

  def average_seconds(values)
    return nil if values.blank?

    (values.sum.to_f / values.size).round
  end

  def daily_response_times(employee, replies_today, range)
    conversation_ids = replies_today.distinct.pluck(:conversation_id)
    return [] if conversation_ids.blank?

    response_times = []
    pending_customer_message_at = nil
    current_conversation_id = nil
    messages_for_response_report(conversation_ids, range.end).each do |message|
      if current_conversation_id != message.conversation_id
        current_conversation_id = message.conversation_id
        pending_customer_message_at = nil
      end

      if message.incoming?
        pending_customer_message_at = message.created_at
        next
      end

      next unless message.outgoing? && pending_customer_message_at.present?

      if message.sender_type == 'User' && message.sender_id == employee.id && range.cover?(message.created_at)
        response_times << (message.created_at - pending_customer_message_at).to_i
      end
      pending_customer_message_at = nil
    end

    response_times
  end

  def messages_for_response_report(conversation_ids, report_end)
    Current.account.messages
           .reorder(:conversation_id, :created_at, :id)
           .where(conversation_id: conversation_ids, private: false, created_at: ..report_end)
           .where(message_type: [:incoming, :outgoing])
           .where("sender_type IS NULL OR sender_type NOT IN ('AgentBot', 'Captain::Assistant')")
  end

  def presence_status_for(employee_id, account_user)
    return 'offline' if account_user.blank? || !account_user.active? || account_user.archived_at.present?

    ::OnlineStatusTracker.get_presence(Current.account.id, 'User', employee_id) ? 'online' : 'offline'
  end

  def work_status_for(account_user, presence_status, delayed_count, last_activity_at)
    return nil if account_user.blank? || !account_user.active? || account_user.archived_at.present?
    return nil if presence_status == 'offline'
    return 'not_responding' if delayed_count.positive?
    return 'working' if last_activity_at.present? && last_activity_at >= idle_threshold

    'idle'
  end

  def account_status_for(account_user)
    return 'archived' if account_user&.archived_at.present?
    return 'active' if account_user&.active?

    'inactive'
  end

  def seconds_since(timestamp)
    return nil if timestamp.blank?

    (Time.current - timestamp).to_i
  end

  def idle_threshold
    idle_after_minutes.minutes.ago
  end

  def not_responding_threshold
    not_responding_after_minutes.minutes.ago
  end

  def idle_after_minutes
    params[:idle_after_minutes].presence&.to_i || IDLE_AFTER_MINUTES
  end

  def not_responding_after_minutes
    params[:not_responding_after_minutes].presence&.to_i || NOT_RESPONDING_AFTER_MINUTES
  end

  def truthy_param?(key)
    ActiveModel::Type::Boolean.new.cast(params[key])
  end

  def older_than_minutes?(timestamp, minutes)
    timestamp.present? && timestamp <= minutes.to_i.minutes.ago
  end

  def activity_message_payload(message)
    {
      id: message.id,
      conversation_id: message.conversation_id,
      conversation_display_id: message.conversation&.display_id,
      content: message.content,
      created_at: message.created_at
    }
  end

  def activity_conversation_payload(conversation)
    {
      id: conversation.id,
      display_id: conversation.display_id,
      status: conversation.status,
      waiting_since: conversation.waiting_since,
      last_activity_at: conversation.last_activity_at,
      inbox_id: conversation.inbox_id,
      team_id: conversation.team_id
    }
  end

  def activity_reporting_event_payload(event)
    {
      id: event.id,
      conversation_id: event.conversation_id,
      conversation_display_id: event.conversation&.display_id,
      value: event.value,
      created_at: event.created_at
    }
  end

  def activity_timeline(employee, replies, resolved_events, metrics)
    events = employee.employee_login_events.where(account: Current.account, success: true).recent.limit(5).map do |event|
      { event_type: 'logged_in', occurred_at: event.created_at, label: 'logged_in', metadata: { ip_address: event.ip_address } }
    end

    events += replies.map do |message|
      {
        event_type: 'reply',
        occurred_at: message.created_at,
        label: 'reply',
        metadata: { conversation_display_id: message.conversation&.display_id }
      }
    end

    events += resolved_events.map do |event|
      {
        event_type: 'resolved',
        occurred_at: event.created_at,
        label: 'resolved',
        metadata: { conversation_display_id: event.conversation&.display_id }
      }
    end

    if metrics[:work_status] == 'idle'
      events << { event_type: 'idle', occurred_at: metrics[:last_activity_at], label: 'idle',
                  metadata: { idle_duration: metrics[:idle_duration] } }
    end
    if metrics[:work_status] == 'not_responding'
      events << { event_type: 'not_responding', occurred_at: metrics[:oldest_waiting_customer_at], label: 'not_responding',
                  metadata: { waiting_seconds: metrics[:oldest_waiting_customer_seconds] } }
    end

    events.compact.sort_by { |event| event[:occurred_at] || Time.zone.at(0) }.last(20).reverse
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
# rubocop:enable Metrics/ClassLength
