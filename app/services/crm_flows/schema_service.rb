module CrmFlows
  class SchemaService
    BASE_FIELDS = [
      { 'key' => 'name', 'label' => 'Nombre', 'source' => 'contact.name', 'required' => true },
      { 'key' => 'email', 'label' => 'Email', 'source' => 'contact.email', 'required' => false },
      { 'key' => 'phone', 'label' => 'Teléfono', 'source' => 'contact.phone_number', 'required' => false }
    ].freeze

    def initialize(flow)
      @flow = flow
    end

    def schema
      {
        flow: {
          id: @flow.id,
          name: @flow.name,
          trigger_type: @flow.trigger_type,
          scope_type: @flow.scope_type,
          inbox_id: @flow.inbox_id,
          base_fields: BASE_FIELDS,
          custom_fields: @flow.required_fields || []
        }
      }
    end
  end
end
