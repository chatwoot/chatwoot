class CrmFlows::ActionExecutor
  CRM_ACTIONS = %w[
    create_lead
    create_contact
    create_opportunity
    create_call
    create_task
    create_event
    add_crm_tag
    add_note
    create_appointment
    update_appointment_status
    update_lead
    update_contact
    create_ticket
  ].freeze
  DESK_ACTIONS = %w[create_ticket].freeze
  CHATWOOT_ACTIONS = %w[assign_chatwoot_agent add_chatwoot_label].freeze

  # Mapeo de nombres de acción del flow → nombres que espera el ProcessorService
  PROCESSOR_ACTION_MAP = {
    'add_crm_tag' => 'add_tag'
  }.freeze

  IDEMPOTENCY_STRATEGIES = {
    'create_lead' => :check_external_id,
    'create_opportunity' => :check_external_id,
    'create_event' => :check_external_id,
    'create_appointment' => :check_appointment_external_id,
    'update_appointment_status' => :always_sync,
    'add_crm_tag' => :idempotent_by_nature,
    'create_task' => :none,
    'create_call' => :none,
    'add_note' => :none,
    'create_ticket' => :none
  }.freeze

  def initialize(account:, contact:, conversation:, metadata: {})
    @account = account
    @contact = contact
    @conversation = conversation
    @metadata = metadata
    @crm_hooks = Integrations::Hook.where(account_id: account.id).crm_hooks.enabled
  end

  def execute(actions)
    results = []
    (actions || []).sort_by { |a| a['order'] || 0 }.each do |action|
      Rails.logger.info "Executing action: #{action['action']}"
      if CHATWOOT_ACTIONS.include?(action['action'])
        results << execute_chatwoot_action(action)
      elsif CRM_ACTIONS.include?(action['action'])
        # Skip CRM actions for visitor contacts
        if @contact.contact_type == 'visitor'
          Rails.logger.info "Skipping CRM action #{action['action']} for visitor contact #{@contact.id}"
          results << {
            action: action['action'],
            status: 'skipped',
            reason: 'visitor_contact',
            message: 'CRM actions are not executed for visitor contacts',
            type: 'crm'
          }
          next
        end
        results.concat(execute_crm_action(action))
      end
    end
    Rails.logger.info "Execution results: #{results}"
    results
  end

  private

  def execute_chatwoot_action(action)
    case action['action']
    when 'assign_chatwoot_agent' then assign_agent(action)
    when 'add_chatwoot_label'    then add_label(action)
    else { action: action['action'], status: 'failed', error: 'Unknown chatwoot action', type: 'chatwoot' }
    end
  end

  def assign_agent(action)
    agent_id = action.dig('params', 'agent_id')
    return { action: 'assign_chatwoot_agent', status: 'failed', error: 'agent_id missing', type: 'chatwoot' } if agent_id.blank?

    @conversation.update!(assignee_id: agent_id)
    { action: 'assign_chatwoot_agent', status: 'success', type: 'chatwoot' }
  rescue StandardError => e
    { action: 'assign_chatwoot_agent', status: 'failed', error: e.message, type: 'chatwoot' }
  end

  def add_label(action)
    label_title = action.dig('params', 'label')
    return { action: 'add_chatwoot_label', status: 'failed', error: 'label missing', type: 'chatwoot' } if label_title.blank?

    existing = @conversation.labels || []
    @conversation.labels = (existing + [label_title]).uniq
    @conversation.save!
    { action: 'add_chatwoot_label', status: 'success', type: 'chatwoot' }
  rescue StandardError => e
    { action: 'add_chatwoot_label', status: 'failed', error: e.message, type: 'chatwoot' }
  end

  def execute_crm_action(action)
      hooks = if DESK_ACTIONS.include?(action['action'])
              @crm_hooks.select { |h| h.app_id == 'zoho' && h.settings&.dig('desk_soid').present? }
            else
              @crm_hooks
            end

      hooks.map do |hook|
      # Validar autenticación antes de ejecutar
      unless hook_authenticated?(hook)
        next {
          action: action['action'],
          crm: hook.app_id,
          status: 'skipped',
          reason: 'not_authenticated',
          type: 'crm'
        }
      end

      execute_single_crm_action(hook, action)
    end
  end

  def execute_single_crm_action(hook, action)
    action_name = action['action']
    crm_name = hook.app_id

    # ROUTING INTELIGENTE: Si es create_appointment, resolver el action correcto por tipo
    if action_name == 'create_appointment'
      appointment = Appointment.find_by(id: @metadata[:appointment_id])
      return { action: action_name, crm: crm_name, status: 'failed', error: 'Appointment not found', type: 'crm' } unless appointment

      config = Crm::AppointmentTypeConfig.resolve(crm_name, appointment.appointment_type)
      return { action: action_name, crm: crm_name, status: 'skipped', reason: 'unsupported_type', type: 'crm' } unless config

      action_name = config[:action] # create_call, create_event, create_task, etc.
    end

    strategy = IDEMPOTENCY_STRATEGIES[action['action']] # Usar action original para strategy
    if strategy == :check_external_id && external_id_exists?(hook, action['action'])
      # Si es create_lead o create_contact y necesita sincronización, sincronizar en lugar de skip
      return sync_lead_profile(hook, action) if %w[create_lead create_contact].include?(action['action']) && should_sync_profile?(hook)

      return { action: action['action'], crm: crm_name, status: 'skipped', reason: 'already_exists', type: 'crm' }
    end

    if strategy == :check_appointment_external_id && appointment_external_id_exists?(hook)
      return { action: action['action'], crm: crm_name, status: 'skipped', reason: 'already_synced', type: 'crm' }
    end

    processor = build_processor(hook)
    return { action: action['action'], crm: crm_name, status: 'skipped', reason: 'unsupported', type: 'crm' } unless processor

    params = build_params(action)
    processor_action = PROCESSOR_ACTION_MAP[action_name] || action_name
    result = processor.execute_action(processor_action, params)

    if result[:success]
      eid = result[:lead_id] || result[:contact_id] || result[:call_id] ||
            result[:task_id] || result[:event_id] || result[:opportunity_id] || result[:note_id] || result[:ticket_id]
      { action: action['action'], crm: crm_name, status: 'success', external_id: eid, type: 'crm' }
    else
      { action: action['action'], crm: crm_name, status: 'failed', error: result[:error], type: 'crm' }
    end
  rescue StandardError => e
    Rails.logger.error "CrmFlows::ActionExecutor (#{action['action']}/#{hook.app_id}): #{e.message}"
    { action: action['action'], crm: hook.app_id, status: 'failed', error: e.message, type: 'crm' }
  end

  def external_id_exists?(hook, action_name)
    case action_name
    when 'create_lead'
      @contact.additional_attributes&.dig('external', "#{hook.app_id}_lead_id").present?
    when 'create_contact'
      @contact.additional_attributes&.dig('external', "#{hook.app_id}_contact_id").present?
    when 'create_opportunity'
      @contact.additional_attributes&.dig('external', "#{hook.app_id}_opportunity_id").present?
    when 'create_appointment'
      appointment_external_id_exists?(hook)
    else
      false
    end
  end

  def appointment_external_id_exists?(hook)
    appointment = Appointment.find_by(id: @metadata[:appointment_id])
    return false unless appointment

    appointment.external_id_for(hook.app_id).present?
  end

  def hook_authenticated?(hook)
    processor = build_processor(hook)
    processor&.authenticated?
  rescue StandardError => e
    Rails.logger.error "Authentication check failed for #{hook.app_id}: #{e.message}"
    false
  end

  def build_processor(hook)
    case hook.app_id
    when 'zoho'       then Crm::Zoho::ProcessorService.new(hook)
    when 'salesforce' then Crm::Salesforce::ProcessorService.new(hook)
    when 'hubspot'    then Crm::Hubspot::ProcessorService.new(hook)
    end
  rescue StandardError
    nil
  end

  def build_params(action)
    base_params = (action['params'] || {}).merge(
      'contact_id' => @contact.id,
      'metadata' => @metadata
    )

    # Si hay appointment_id en metadata, añadirlo directamente a params
    meta = @metadata.with_indifferent_access
    base_params['appointment_id'] = meta[:appointment_id] if meta[:appointment_id].present?

    # Promote custom fields from metadata if present
    %w[lead_custom_fields contact_custom_fields].each do |key|
      base_params[key] = meta[key] if meta[key].present?
    end

    # Resolve CRM owner ID using OwnerResolver
    appointment = @metadata[:appointment_id].present? ? Appointment.find_by(id: @metadata[:appointment_id]) : nil
    owner_id = resolve_owner_id(appointment: appointment)
    base_params['owner_id'] = owner_id if owner_id.present?

    base_params.symbolize_keys
  end

  # Resolve CRM owner ID using OwnerResolver
  # Uses priority: metadata > appointment.owner > conversation.assignee
  #
  # @param appointment [Appointment, nil] Optional appointment
  # @return [String, nil] CRM external ID or nil
  def resolve_owner_id(appointment: nil)
    @owner_resolver ||= CrmFlows::OwnerResolver.new(
      account: @account,
      conversation: @conversation,
      appointment: appointment,
      metadata: @metadata
    )
    @owner_resolver.resolve
  end

  # Check if profile should be synced based on last sync time
  #
  # @param hook [Integrations::Hook] CRM hook
  # @return [Boolean] true if sync is needed
  def should_sync_profile?(hook)
    # Check if sync is enabled via ENV
    return false unless ENV['CRM_PROFILE_SYNC_ENABLED'] == 'true'

    crm_name = hook.app_id
    last_synced = @contact.additional_attributes
                          &.dig('crm_metadata', crm_name, 'last_synced_at')

    # If never synced, sync now
    return true if last_synced.blank?

    # Check if sync interval has passed
    interval_hours = ENV.fetch('CRM_PROFILE_SYNC_INTERVAL_HOURS', '24').to_i
    interval = interval_hours.hours

    Time.zone.parse(last_synced) < interval.ago
  rescue StandardError => e
    Rails.logger.error "Error checking sync profile status: #{e.message}"
    true # If error, sync to be safe
  end

  # Sync lead profile from CRM
  #
  # @param hook [Integrations::Hook] CRM hook
  # @param action [Hash] Original action hash
  # @return [Hash] Result hash
  def sync_lead_profile(hook, action)
    processor = build_processor(hook)
    return { action: action['action'], crm: hook.app_id, status: 'skipped', reason: 'no_processor', type: 'crm' } unless processor

    result = processor.sync_profile(@contact)

    if result[:success]
      {
        action: action['action'],
        crm: hook.app_id,
        status: 'success',
        reason: 'profile_synced',
        synced_fields: result[:synced_fields],
        type: 'crm'
      }
    else
      {
        action: action['action'],
        crm: hook.app_id,
        status: 'skipped',
        reason: 'sync_failed',
        error: result[:error],
        type: 'crm'
      }
    end
  rescue StandardError => e
    Rails.logger.error "Error syncing lead profile: #{e.message}"
    {
      action: action['action'],
      crm: hook.app_id,
      status: 'skipped',
      reason: 'sync_error',
      error: e.message,
      type: 'crm'
    }
  end
end
