module Enterprise::Api::V1::Accounts::AutomationRulesController
  def index
    super
    if params.key?(:monitor_id)
      return render_could_not_create_error('invalid_monitor_id') unless params[:monitor_id].to_s.match?(/\A[1-9]\d*\z/)

      @automation_rules = @automation_rules.where(monitor_id: params[:monitor_id])
    end
    @automation_rules = @automation_rules.includes(monitor: :account)
  end

  def create
    with_monitor_lock(params[:event_name], params[:monitor_id]) { super }
  end

  def update
    event_name = params[:event_name] || @automation_rule.event_name
    monitor_id = params.key?(:monitor_id) ? params[:monitor_id] : @automation_rule.monitor_id
    with_monitor_lock(event_name, monitor_id) { super }
  end

  def clone
    source = Current.account.automation_rules.find_by(id: params[:automation_rule_id])
    return super unless source&.event_name == 'monitor_matched'

    with_monitor_lock(source.event_name, source.monitor_id, require_active: true) { super }
  end

  private

  def automation_rules_permit
    super.merge(params.permit(:monitor_id))
  end

  def with_monitor_lock(event_name, monitor_id, require_active: nil, &)
    return yield unless event_name == 'monitor_matched'
    return render_could_not_create_error('invalid_active') if invalid_active_parameter?
    return yield if require_active.nil? && orphaned_inactive_rule?(monitor_id)
    return render_could_not_create_error('invalid_monitor_id') unless valid_monitor_id?(monitor_id)

    monitor = Current.account.conversation_monitors.find_by(id: monitor_id)
    return render_could_not_create_error('monitor_not_available') unless monitor

    monitor.with_lock { validate_monitor_and_yield(monitor, require_active, &) }
  end

  def invalid_active_parameter?
    params.key?(:active) && [true, false].exclude?(params[:active])
  end

  def valid_monitor_id?(monitor_id)
    monitor_id.is_a?(Integer) && monitor_id.positive?
  end

  def validate_monitor_and_yield(monitor, require_active)
    if live_monitor_required?(monitor, require_active) && (!monitor.collecting? || !monitor.account.feature_enabled?('automations'))
      return render_could_not_create_error('monitor_not_available')
    end

    yield
  end

  def live_monitor_required?(monitor, require_active)
    activation_requested?(require_active) || !@automation_rule || @automation_rule.monitor_id != monitor.id ||
      @automation_rule.event_name != 'monitor_matched'
  end

  def orphaned_inactive_rule?(monitor_id)
    @automation_rule&.persisted? && @automation_rule.event_name == 'monitor_matched' &&
      !@automation_rule.active? && monitor_id.nil? && params[:active] != true
  end

  def activation_requested?(require_active)
    return require_active unless require_active.nil?
    return params[:active] if params.key?(:active)

    @automation_rule ? @automation_rule.active? : true
  end
end
