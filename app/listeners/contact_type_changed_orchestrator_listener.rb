# frozen_string_literal: true

# Listener for orchestrating CRM synchronization when contact type changes
#
# Listens to contact update events and triggers appropriate CRM flows
# when a contact's type changes (visitor→lead, lead→customer, etc.)
#
# Events handled:
# - contact.updated → execute CRM flows with trigger_type "contact_type_changed"
#
# Metadata includes:
# - from_type: Previous contact type
# - to_type: New contact type
# - This allows flows to have conditional logic based on the transition
class ContactTypeChangedOrchestratorListener < BaseListener
  # Handle contact update event
  #
  # Triggers CRM flows when contact_type changes
  def contact_updated(event)
    contact = event.data[:contact]
    changed_attributes = event.data[:changed_attributes]

    return unless changed_attributes
    return unless changed_attributes.key?('contact_type')

    old_type, new_type = changed_attributes['contact_type']

    Rails.logger.info "ContactTypeChangedOrchestratorListener: Contact #{contact.id} type changed from #{old_type} to #{new_type}"
    execute_flows_for_type_change(contact, old_type, new_type)
  rescue StandardError => e
    Rails.logger.error "ContactTypeChangedOrchestratorListener#contact_updated failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  # Execute CRM flows for contact type change
  #
  # @param contact [Contact] The contact whose type changed
  # @param from_type [String] Previous type
  # @param to_type [String] New type
  def execute_flows_for_type_change(contact, from_type, to_type)
    account = contact.account
    return unless account

    # Buscar conversación más reciente para contexto
    conversation = contact.conversations.order(created_at: :desc).first

    # Resolver flow activo para este trigger
    flow = CrmFlow.resolve_for(
      account_id: account.id,
      trigger_type: 'contact_type_changed',
      inbox_id: conversation&.inbox_id
    )

    unless flow
      Rails.logger.debug { "No active CRM flow for contact_type_changed (account: #{account.id})" }
      return
    end

    Rails.logger.info "Found CRM flow: #{flow.name} (id: #{flow.id})"

    # Validar que existen hooks habilitados y autenticados
    enabled_hooks = get_enabled_and_authenticated_hooks(account)

    if enabled_hooks.empty?
      Rails.logger.info "No CRM hooks enabled for contact_type_changed (account: #{account.id})"
      return
    end

    # Ejecutar el flow
    Rails.logger.info "Executing contact_type_changed flow: #{flow.name} (#{from_type}→#{to_type})"
    execute_flow_for_contact(flow, contact, conversation, from_type, to_type)
  end

  # Execute a single CRM flow for contact type change
  #
  # @param flow [CrmFlow] The CRM flow to execute
  # @param contact [Contact] The contact whose type changed
  # @param conversation [Conversation, nil] Most recent conversation (if exists)
  # @param from_type [String] Previous type
  # @param to_type [String] New type
  def execute_flow_for_contact(flow, contact, conversation, from_type, to_type)
    # Construir metadata con información de la transición
    metadata = build_contact_metadata(contact, from_type, to_type)

    # Ejecutar vía ActionExecutor
    executor = CrmFlows::ActionExecutor.new(
      account: contact.account,
      contact: contact,
      conversation: conversation,
      metadata: metadata
    )

    results = executor.execute(flow.actions)

    # Registrar ejecución
    status = determine_execution_status(results)

    CrmFlowExecution.create!(
      crm_flow: flow,
      conversation: conversation,
      contact: contact,
      status: status,
      results: results
    )

    Rails.logger.info "Contact type changed flow executed for contact #{contact.id} (status: #{status})"
  rescue StandardError => e
    Rails.logger.error "Failed to execute contact_type_changed flow #{flow.id} for contact #{contact.id}: #{e.message}"
  end

  # Build metadata object from contact with type change info
  #
  # @param contact [Contact] The contact
  # @param from_type [String] Previous type
  # @param to_type [String] New type
  # @return [Hash] Metadata for ActionExecutor
  def build_contact_metadata(contact, from_type, to_type)
    {
      contact_id: contact.id,
      contact_type: contact.contact_type,
      from_type: from_type,
      to_type: to_type,
      name: contact.name,
      email: contact.email,
      phone_number: contact.phone_number,
      identifier: contact.identifier,
      custom_attributes: contact.custom_attributes,
      additional_attributes: contact.additional_attributes
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
        processor = build_processor(hook)
        processor&.authenticated?
      rescue StandardError => e
        Rails.logger.error "Hook authentication failed for #{hook.app_id}: #{e.message}"
        false
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
      'success'
    else
      'failed'
    end
  end
end
