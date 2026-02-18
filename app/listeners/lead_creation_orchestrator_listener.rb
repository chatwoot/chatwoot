# frozen_string_literal: true

# Listener for orchestrating automatic CRM synchronization when leads are created
#
# Listens to contact creation events and triggers appropriate CRM flows
# to sync contact data to external CRMs (Zoho, Salesforce, HubSpot, etc.)
#
# Events handled:
# - contact.created → execute CRM flows with trigger_type "lead_creation"
#
# Validations:
# - Only triggers if CRM Flow is active
# - Only triggers if CRM Hook is enabled
# - Only triggers if CRM Hook is authenticated (valid token)
# - Skips trigger gracefully if validations fail (doesn't block contact creation)
class LeadCreationOrchestratorListener < BaseListener
  # Handle conversation creation event
  #
  # Triggers CRM flows to create lead in external CRMs when a new conversation is created
  # This ensures the contact already has the contact_inbox association
  def conversation_created(event)
    Rails.logger.info 'LeadCreationOrchestratorListener#conversation_created CALLED!'
    Rails.logger.info "Event data: #{event.data.inspect}"

    conversation = event.data[:conversation]
    return unless conversation

    contact = conversation.contact
    return unless contact

    # Solo ejecutar si es una conversación nueva (primera del contact) o si el contact es reciente
    # Esto evita ejecutar el flow en conversaciones subsecuentes del mismo contact
    return if contact.conversations.count > 1 && contact.created_at < 5.minutes.ago

    Rails.logger.info "Processing lead creation for contact #{contact.id} via conversation #{conversation.id}"
    execute_flows_for_conversation(conversation, contact)
    Rails.logger.info "Lead creation flows completed for contact #{contact.id}"
  rescue StandardError => e
    Rails.logger.error "LeadCreationOrchestratorListener#conversation_created failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  # Execute CRM flows for conversation creation
  #
  # @param conversation [Conversation] The conversation that was created
  # @param contact [Contact] The contact associated with the conversation
  def execute_flows_for_conversation(conversation, contact)
    account = conversation.account
    return unless account

    inbox_id = conversation.inbox_id

    # Resolver flow activo para este trigger e inbox
    flow = CrmFlow.resolve_for(
      account_id: account.id,
      trigger_type: 'lead_creation',
      inbox_id: inbox_id
    )

    unless flow
      Rails.logger.debug { "No active CRM flow for lead_creation (account: #{account.id}, inbox: #{inbox_id})" }
      return
    end

    Rails.logger.info "Found CRM flow: #{flow.name} (id: #{flow.id})"

    # Validar que existen hooks habilitados y autenticados
    enabled_hooks = get_enabled_and_authenticated_hooks(account)
    Rails.logger.info "Found #{enabled_hooks.count} enabled and authenticated hooks"

    if enabled_hooks.empty?
      Rails.logger.info "No CRM hooks enabled for lead creation (account: #{account.id})"
      return
    end

    # Ejecutar el flow
    Rails.logger.info "Executing flow: #{flow.name} (id: #{flow.id})"
    execute_flow_for_contact(flow, contact, conversation)
  end

  # Execute a single CRM flow for contact creation
  #
  # @param flow [CrmFlow] The CRM flow to execute
  # @param contact [Contact] The contact that was created
  # @param conversation [Conversation, nil] Associated conversation (if exists)
  def execute_flow_for_contact(flow, contact, conversation)
    # Construir metadata del contact
    metadata = build_contact_metadata(contact)

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

    Rails.logger.info "CRM flow executed for contact #{contact.id} (status: #{status})"
  rescue StandardError => e
    Rails.logger.error "Failed to execute CRM flow #{flow.id} for contact #{contact.id}: #{e.message}"
  end

  # Build metadata object from contact
  #
  # @param contact [Contact] The contact
  # @return [Hash] Metadata for ActionExecutor
  def build_contact_metadata(contact)
    {
      contact_id: contact.id,
      contact_type: contact.contact_type,
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
        # Validar autenticación

        processor = build_processor(hook)
        processor&.authenticated?
    rescue StandardError => e
      Rails.logger.error "Hook authentication failed for #{hook.app_id} (account: #{account.id}): #{e.message}"
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
      'success' # All skipped (e.g., already exists) is still success
    else
      'failed'
    end
  end
end
