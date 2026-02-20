module CrmFlows
  class TriggerService
    def initialize(account:, trigger_type:, conversation_id:, contact_id:, metadata: {}, idempotency_key:)
      @account = account
      @trigger_type = trigger_type
      @conversation_id = conversation_id
      @contact_id = contact_id
      @metadata = metadata
      @idempotency_key = idempotency_key
    end

    def call
      # Capa 1: idempotency key
      cached = IdempotencyService.check(@idempotency_key)
      return handle_cached(cached) if cached

      # Resolve flow por prioridad inbox > global
      conversation = Conversation.find_by(id: @conversation_id)
      flow = CrmFlow.resolve_for(
        account_id: @account.id,
        trigger_type: @trigger_type,
        inbox_id: conversation&.inbox_id
      )
      return { status: :not_found, error: 'No CRM Flow configurado para este trigger' } unless flow

      # Capa 3: ventana de deduplicación
      return { status: :deduplicated } if duplicate?(flow)

      # Validación de campos requeridos
      validation = validate_fields(flow)
      return { status: :validation_failed, missing_fields: validation[:missing] } unless validation[:valid]

      # Almacenar pending y encolear
      IdempotencyService.store_pending(@idempotency_key, flow_id: flow.id, conversation_id: @conversation_id)

      ticket = create_ticket(conversation) if flow.trigger_type == 'ticket_created'

      CrmFlows::ExecutionJob.perform_later(
        flow_id: flow.id,
        conversation_id: @conversation_id,
        contact_id: @contact_id,
        metadata: @metadata,
        idempotency_key: @idempotency_key,
        ticket_id: ticket&.id
      )

      { status: :queued, flow_id: flow.id, flow_name: flow.name }
    end

    private

    def handle_cached(cached)
      case cached['status']
      when 'pending'   then { status: :processing }
      when 'completed' then { status: :completed, result: cached['response'] }
      when 'failed'    then { status: :failed, error: cached['error'] }
      end
    end

    def duplicate?(flow)
      window = flow.dedup_window_minutes.minutes.ago
      scope = CrmFlowExecution.where(crm_flow_id: flow.id, status: 'success')
                               .where('created_at > ?', window)

      if @conversation_id.present?
        scope = scope.where(conversation_id: @conversation_id)
      else
        scope = scope.where(conversation_id: nil, contact_id: @contact_id)
      end

      scope.exists?
    end

    def validate_fields(flow)
      missing = flow.required_custom_fields.reject { |f| @metadata[f['key']].present? }
      {
        valid: missing.empty?,
        missing: missing.map { |f| { key: f['key'], label: f['label'], type: f['type'] } }
      }
    end

    def create_ticket(conversation)
      contact = Contact.find_by(id: @contact_id)
      stringified = @metadata.stringify_keys
      Ticket.create!(
        account: @account,
        contact: contact,
        conversation: conversation,
        subject: stringified['ticket_subject'].presence || stringified['subject'].presence || 'Untitled Ticket',
        description: stringified['ticket_description'].presence || stringified['description'],
        priority: stringified['priority'],
        classification: stringified['classification'],
        metadata: @metadata
      )
    end
  end
end
