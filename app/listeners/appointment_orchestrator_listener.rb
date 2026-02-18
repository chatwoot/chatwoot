# frozen_string_literal: true

# Listener for orchestrating automatic CRM synchronization of appointments
#
# Listens to appointment lifecycle events and triggers appropriate CRM flows
# to sync appointment data to external CRMs (Zoho, Salesforce, HubSpot, etc.)
#
# Events handled:
# - appointment.created → sync new appointment to CRM
# - appointment.started → update status to in_progress
# - appointment.completed → update status to completed
# - appointment.cancelled → update status to cancelled
# - appointment.discarded → mark as cancelled or delete
#
# Validations:
# - Only syncs if CRM Flow is active
# - Only syncs if CRM Hook is enabled
# - Only syncs if CRM Hook is authenticated (valid token)
# - Skips sync gracefully if validations fail (doesn't block appointment creation)
class AppointmentOrchestratorListener < BaseListener
  # Handle appointment creation event
  #
  # Triggers CRM flows to create appointment in external CRMs
  def appointment_created(event)
    Rails.logger.info "🔥 AppointmentOrchestratorListener#appointment_created CALLED!"
    Rails.logger.info "🔥 Event data: #{event.data.inspect}"

    appointment = event.data[:appointment]
    Rails.logger.info "🔥 Appointment: #{appointment.inspect}"

    return unless appointment

    Rails.logger.info "🔥 About to execute_flows_for_appointment"
    execute_flows_for_appointment(appointment, 'created')
    Rails.logger.info "🔥 execute_flows_for_appointment COMPLETED"
  rescue StandardError => e
    Rails.logger.error "🔥 AppointmentOrchestratorListener#appointment_created failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  # Handle appointment started event
  #
  # Updates appointment status to 'in_progress' in external CRMs
  def appointment_started(event)
    appointment = event.data[:appointment]
    return unless appointment

    execute_flows_for_appointment(appointment, 'started')
  rescue StandardError => e
    Rails.logger.error "AppointmentOrchestratorListener#appointment_started failed: #{e.message}"
  end

  # Handle appointment completed event
  #
  # Updates appointment status to 'completed' in external CRMs
  def appointment_completed(event)
    appointment = event.data[:appointment]
    return unless appointment

    execute_flows_for_appointment(appointment, 'completed')
  rescue StandardError => e
    Rails.logger.error "AppointmentOrchestratorListener#appointment_completed failed: #{e.message}"
  end

  # Handle appointment cancelled event
  #
  # Updates appointment status to 'cancelled' in external CRMs
  def appointment_cancelled(event)
    appointment = event.data[:appointment]
    return unless appointment

    execute_flows_for_appointment(appointment, 'cancelled')
  rescue StandardError => e
    Rails.logger.error "AppointmentOrchestratorListener#appointment_cancelled failed: #{e.message}"
  end

  # Handle appointment discarded event
  #
  # Marks appointment as cancelled in external CRMs
  def appointment_discarded(event)
    appointment = event.data[:appointment]
    return unless appointment

    execute_flows_for_appointment(appointment, 'discarded')
  rescue StandardError => e
    Rails.logger.error "AppointmentOrchestratorListener#appointment_discarded failed: #{e.message}"
  end

  private

  # Execute CRM flows for an appointment event
  #
  # @param appointment [Appointment] The appointment to sync
  # @param event_type [String] Type of event ('created', 'started', 'completed', 'cancelled', 'discarded')
  def execute_flows_for_appointment(appointment, event_type)
    Rails.logger.info "🔥 execute_flows_for_appointment START"

    account = appointment.account
    contact = appointment.contact

    Rails.logger.info "🔥 Account: #{account&.id}, Contact: #{contact&.id}"

    return unless account && contact

    # Resolver flows activos con trigger: "appointment_scheduling"
    flows = CrmFlow.where(
      account_id: account.id,
      trigger_type: 'appointment_scheduling',
      active: true
    )

    Rails.logger.info "🔥 Found #{flows.count} active CRM flows for appointment_scheduling"

    if flows.empty?
      Rails.logger.debug "No active CRM flows for appointment_scheduling (account: #{account.id})"
      return
    end

    # Validar que existen hooks habilitados y autenticados
    enabled_hooks = get_enabled_and_authenticated_hooks(account)
    Rails.logger.info "🔥 Found #{enabled_hooks.count} enabled and authenticated hooks"

    if enabled_hooks.empty?
      Rails.logger.info "No CRM hooks enabled for appointment sync (account: #{account.id})"
      return
    end

    # Ejecutar cada flow
    flows.each do |flow|
      Rails.logger.info "🔥 Executing flow: #{flow.name} (id: #{flow.id})"
      execute_flow_for_event(flow, appointment, contact, event_type)
    end

    Rails.logger.info "🔥 execute_flows_for_appointment END"
  end

  # Execute a single CRM flow for an appointment event
  #
  # @param flow [CrmFlow] The CRM flow to execute
  # @param appointment [Appointment] The appointment to sync
  # @param contact [Contact] The associated contact
  # @param event_type [String] Type of event
  def execute_flow_for_event(flow, appointment, contact, event_type)
    # Determinar la acción según el tipo de evento
    actions = build_actions_for_event(flow, event_type, appointment)

    return if actions.empty?

    # Construir metadata del appointment
    metadata = build_appointment_metadata(appointment)

    # Ejecutar vía ActionExecutor
    executor = CrmFlows::ActionExecutor.new(
      account: appointment.account,
      contact: contact,
      conversation: appointment.conversation,
      metadata: metadata
    )

    results = executor.execute(actions)

    # Registrar ejecución
    status = determine_execution_status(results)

    CrmFlowExecution.create!(
      crm_flow: flow,
      conversation: appointment.conversation,
      contact: contact,
      status: status,
      results: results
    )

    Rails.logger.info "CRM flow executed for appointment #{appointment.id} (event: #{event_type}, status: #{status})"
  rescue StandardError => e
    Rails.logger.error "Failed to execute CRM flow #{flow.id} for appointment #{appointment.id}: #{e.message}"
  end

  # Build actions based on event type
  #
  # @param flow [CrmFlow] The CRM flow
  # @param event_type [String] Type of event
  # @param appointment [Appointment] The appointment
  # @return [Array<Hash>] List of actions to execute
  def build_actions_for_event(flow, event_type, appointment)
    case event_type
    when 'created'
      # Para created, usar las acciones del flow o una acción por defecto
      if flow.actions.present?
        flow.actions
      else
        [{ 'order' => 1, 'action' => 'create_appointment', 'params' => {} }]
      end
    when 'started', 'completed', 'cancelled', 'discarded'
      # Para cambios de estado, solo sincronizar si ya existe external_id
      return [] if appointment.external_ids.blank?

      [{ 'order' => 1, 'action' => 'update_appointment_status', 'params' => {} }]
    else
      []
    end
  end

  # Build metadata object from appointment
  #
  # @param appointment [Appointment] The appointment
  # @return [Hash] Metadata for ActionExecutor
  def build_appointment_metadata(appointment)
    {
      appointment_id: appointment.id,
      appointment_type: appointment.appointment_type,
      scheduled_at: appointment.scheduled_at&.iso8601,
      ended_at: appointment.ended_at&.iso8601,
      started_at: appointment.started_at&.iso8601,
      status: appointment.status,
      location: appointment.location,
      meeting_url: appointment.meeting_url,
      phone_number: appointment.phone_number,
      description: appointment.description,
      duration_minutes: appointment.duration_minutes,
      participants: appointment.participants,
      owner_id: appointment.owner_id
    }.compact
  end

  # Get enabled and authenticated CRM hooks for account
  #
  # @param account [Account] The account
  # @return [Array<Integrations::Hook>] List of valid hooks
  def get_enabled_and_authenticated_hooks(account)
    Integrations::Hook
      .where(account_id: account.id)
      .crm_hooks
      .enabled
      .select do |hook|
        # Validar autenticación
        begin
          processor = build_processor(hook)
          processor&.authenticated?
        rescue StandardError => e
          Rails.logger.error "Hook authentication failed for #{hook.app_id} (account: #{account.id}): #{e.message}"
          false
        end
      end
  end

  # Build processor for hook
  #
  # @param hook [Integrations::Hook] The CRM hook
  # @return [Crm::BaseProcessorService, nil] Processor instance or nil
  def build_processor(hook)
    case hook.app_id
    when 'zoho'       then Crm::Zoho::ProcessorService.new(hook)
    when 'salesforce' then Crm::Salesforce::ProcessorService.new(hook)
    when 'hubspot'    then Crm::Hubspot::ProcessorService.new(hook)
    end
  rescue StandardError
    nil
  end

  # Determine execution status from results
  #
  # @param results [Array<Hash>] Execution results from ActionExecutor
  # @return [String] Status ('success', 'partial', 'failed')
  def determine_execution_status(results)
    return 'failed' if results.empty?

    successes = results.count { |r| r[:status] == 'success' }
    failures = results.count { |r| r[:status] == 'failed' }
    skipped = results.count { |r| r[:status] == 'skipped' }

    if successes.positive? && failures.zero?
      'success'
    elsif successes.positive? && failures.positive?
      'partial'
    elsif skipped.positive? && failures.zero?
      'success' # All skipped (e.g., already exists) is still success
    else
      'failed'
    end
  end
end
