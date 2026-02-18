# frozen_string_literal: true

module CrmFlows
  # Builds the metadata schema an AI agent needs before triggering a CRM flow.
  #
  # For each active flow matching the trigger:
  #   - resolves which actions will run
  #   - declares what metadata each action requires
  #   - auto-fills fields available on the Contact (name, email, phone)
  #   - returns the rest as `missing` so the agent can ask the user
  class AgentSchemaService
    # Per-action metadata definitions (unified across Zoho / SF / HubSpot).
    # contact_fields: keys extracted automatically from the Contact.
    # required / optional: metadata the caller must supply.
    ACTION_SCHEMAS = {
      'create_lead' => {
        contact_fields: %i[name email phone],
        required: [],
        optional: []
      },
      'create_task' => {
        contact_fields: [],
        required: [
          { key: 'subject', label: 'Asunto', type: 'string' }
        ],
        optional: [
          { key: 'description', label: 'Descripción', type: 'string' },
          { key: 'due_date',    label: 'Fecha límite', type: 'date' },
          { key: 'priority',    label: 'Prioridad',    type: 'string' },
          { key: 'status',      label: 'Estado',       type: 'string' }
        ]
      },
      'create_call' => {
        contact_fields: %i[phone],
        required: [
          { key: 'subject',    label: 'Asunto de la llamada', type: 'string' },
          { key: 'start_time', label: 'Fecha y hora',         type: 'datetime' }
        ],
        optional: [
          { key: 'description', label: 'Descripción', type: 'string' },
          { key: 'end_time',    label: 'Hora de fin', type: 'datetime' }
        ]
      },
      'create_event' => {
        contact_fields: [],
        required: [
          { key: 'subject',    label: 'Título del evento',      type: 'string' },
          { key: 'start_time', label: 'Fecha y hora de inicio', type: 'datetime' },
          { key: 'end_time',   label: 'Fecha y hora de fin',    type: 'datetime' }
        ],
        optional: [
          { key: 'description', label: 'Descripción', type: 'string' },
          { key: 'venue',       label: 'Lugar',       type: 'string' }
        ]
      },
      'create_opportunity' => {
        contact_fields: [],
        required: [
          { key: 'name',       label: 'Nombre de la oportunidad', type: 'string' },
          { key: 'stage',      label: 'Etapa',                    type: 'string' },
          { key: 'close_date', label: 'Fecha de cierre',          type: 'date' }
        ],
        optional: [
          { key: 'amount',      label: 'Monto',       type: 'number' },
          { key: 'description', label: 'Descripción', type: 'string' }
        ]
      },
      'add_crm_tag' => {
        contact_fields: [],
        required: [
          { key: 'tag_name', label: 'Nombre del tag', type: 'string' }
        ],
        optional: []
      },
      'add_note' => {
        contact_fields: [],
        required: [
          { key: 'note_text', label: 'Contenido de la nota', type: 'string' }
        ],
        optional: [
          { key: 'note_title', label: 'Título de la nota', type: 'string' }
        ]
      }
    }.freeze

    CONTACT_EXTRACTORS = {
      name:  ->(c) { c.name },
      email: ->(c) { c.email },
      phone: ->(c) { c.phone_number }
    }.freeze

    CONTACT_LABELS = {
      name:  'Nombre del contacto',
      email: 'Correo electrónico',
      phone: 'Número de teléfono'
    }.freeze

    def initialize(account:, trigger_type:, contact:, inbox_id: nil)
      @account = account
      @trigger_type = trigger_type
      @contact = contact
      @inbox_id = inbox_id
    end

    def call
      flows = resolve_flows
      { flows: flows.map { |flow| serialize_flow(flow) } }
    end

    private

    # Mirrors CrmFlow.resolve_for but returns an array (max 1 flow per trigger).
    def resolve_flows
      base = CrmFlow.where(account_id: @account.id).active.by_trigger(@trigger_type)

      if @inbox_id.present?
        inbox_flow = base.where(scope_type: 'inbox', inbox_id: @inbox_id).first
        return [inbox_flow] if inbox_flow
      end

      global_flow = base.where(scope_type: 'global').first
      global_flow ? [global_flow] : []
    end

    def serialize_flow(flow)
      {
        id: flow.id,
        name: flow.name,
        trigger_type: flow.trigger_type,
        flow_fields: serialize_flow_fields(flow),
        actions: (flow.actions || []).sort_by { |a| a['order'] || 0 }.filter_map { |a| serialize_action(a) }
      }
    end

    # Fields declared in the flow's required_fields (validated by TriggerService).
    def serialize_flow_fields(flow)
      (flow.required_fields || []).map do |f|
        { key: f['key'], label: f['label'], type: f['type'] || 'string', required: f['required'] || false }
      end
    end

    def serialize_action(action)
      action_type = action['action']
      schema = ACTION_SCHEMAS[action_type]
      return nil unless schema # skip chatwoot-only actions (assign_agent, add_label)

      # Static params already baked into the flow config (e.g. tag_name for add_crm_tag)
      static_keys = (action['params'] || {}).keys.map(&:to_s)

      prefilled, missing_contact = resolve_contact_fields(schema[:contact_fields])
      missing_metadata = schema[:required].reject { |f| static_keys.include?(f[:key]) }
      available_optional = schema[:optional].reject { |f| static_keys.include?(f[:key]) }

      {
        action: action_type,
        prefilled: prefilled,
        missing: missing_contact + missing_metadata,
        optional: available_optional
      }
    end

    # Splits contact_fields into prefilled (value present) and missing (value blank).
    def resolve_contact_fields(contact_fields)
      prefilled = {}
      missing = []

      (contact_fields || []).each do |field|
        value = CONTACT_EXTRACTORS[field]&.call(@contact)
        if value.present?
          prefilled[field] = value
        else
          missing << { key: field.to_s, label: CONTACT_LABELS[field], type: 'string', required: true }
        end
      end

      [prefilled, missing]
    end
  end
end
