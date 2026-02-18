module CrmFlows
  class ExecutionJob < ApplicationJob
    queue_as :default
    retry_on StandardError, attempts: 3, wait: 5.seconds

    ACTION_LABELS = {
      'create_lead' => 'Lead creado',
      'create_opportunity' => 'Oportunidad creada',
      'create_task' => 'Tarea creada',
      'create_event' => 'Evento creado',
      'add_crm_tag' => 'Etiqueta añadida',
      'add_note' => 'Nota añadida',
      'assign_chatwoot_agent' => 'Asignado a asesor',
      'add_chatwoot_label' => 'Label añadido',
      'create_call' => 'Llamada programada',
      'create_ticket' => 'Ticket creado'
    }.freeze

    def perform(flow_id:, conversation_id:, contact_id:, metadata:, idempotency_key:, ticket_id: nil)
      flow         = CrmFlow.find(flow_id)
      contact      = Contact.find(contact_id)
      conversation = Conversation.find_by(id: conversation_id)
      ticket       = Ticket.find_by(id: ticket_id) if ticket_id

      results = execute_actions(flow, contact, conversation, metadata)
      if ticket
        update_ticket_external_ids(ticket, results)
        sync_pending_attachments(ticket)
      end

      status = compute_status(results)
      execution = record_execution(flow, conversation, contact, status: status, results: results,
                                                                metadata: metadata, idempotency_key: idempotency_key)
      IdempotencyService.store_completed(idempotency_key, response: {
                                           execution_id: execution.id,
                                           status: status,
                                           results: results
                                         })
    rescue StandardError => e
      IdempotencyService.store_failed(idempotency_key, error: e.message) if idempotency_key
      raise
    end

    private

    def execute_actions(flow, contact, conversation, metadata)
      ActionExecutor.new(
        account: flow.account,
        contact: contact,
        conversation: conversation,
        metadata: metadata.stringify_keys
      ).execute(flow.actions)
    end

    def record_execution(flow, conversation, contact, **attrs)
      CrmFlowExecution.create!(
        crm_flow: flow,
        conversation: conversation,
        contact: contact,
        trigger_type: flow.trigger_type,
        **attrs
      )
    end

    def update_ticket_external_ids(ticket, results)
      results.each do |result|
        r = result.with_indifferent_access
        next unless r[:action] == 'create_ticket' && r[:status] == 'success'

        ticket.store_external_id(r[:crm], r[:external_id]) if r[:crm] && r[:external_id]
      end
    end

    def sync_pending_attachments(ticket)
      urls = Array(ticket.metadata&.dig('attachment_urls')).compact_blank
      return if urls.empty?
      return unless ticket.external_id_for('zoho').present?

      hook = find_zoho_desk_hook(ticket.account_id)
      return unless hook

      urls.each do |url|
        Crm::Zoho::TicketUrlAttachmentJob.perform_later(ticket_id: ticket.id, url: url, hook_id: hook.id)
      end
    end

    def find_zoho_desk_hook(account_id)
      Integrations::Hook.where(account_id: account_id).crm_hooks.enabled
                        .find { |h| h.app_id == 'zoho' && h.settings&.dig('desk_soid').present? }
    end

    def compute_status(results)
      statuses = results.map { |r| r[:status] || r['status'] }
      return 'failed' if statuses.all? { |s| s == 'failed' }
      return 'success' if statuses.all? { |s| %w[success skipped].include?(s) }

      'partial'
    end

    def format_line(r)
      action = r[:action] || r['action']
      status = r[:status] || r['status']
      crm    = r[:crm]    || r['crm']
      error  = r[:error]  || r['error']

      label  = ACTION_LABELS[action] || action.to_s.humanize
      suffix = crm ? " en #{crm.capitalize}" : ''

      case status
      when 'success' then "✓ #{label}#{suffix}"
      when 'skipped' then "● #{label}#{suffix} — ya existía"
      when 'failed'  then "✗ #{label}#{suffix} — #{error}"
      end
    end
  end
end
