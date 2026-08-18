class Captain::Routines::AgentRunSchema
  STATUSES = %w[completed no_action needs_follow_up failed].freeze
  FAILURE_OUTCOME = 'agent_failed'.freeze

  class << self
    def for(result_contract)
      outcomes = Array(result_contract.fetch('outcomes'))
      data_schema = build_data_schema(Array(result_contract.fetch('fields')))

      Class.new(RubyLLM::Schema).tap do |schema|
        schema.string :status, enum: STATUSES, description: 'The final status after using the available tools.'
        schema.string :outcome, enum: outcomes, description: 'The normalized business outcome.'
        schema.string :reason, description: 'A concise evidence-based explanation of the outcome.'
        schema.object :data, of: data_schema, description: 'Task-specific structured facts declared by the Routine.'
      end
    end

    private

    def build_data_schema(fields)
      Class.new(RubyLLM::Schema).tap do |schema|
        fields.each { |field| add_field(schema, field) }
      end
    end

    def add_field(schema, field)
      name = field.fetch('name').to_sym
      description = field.fetch('description')

      case field.fetch('type')
      when 'string'
        schema.string(name, description: description)
      when 'string_list'
        schema.array(name, of: :string, description: description)
      when 'enum'
        schema.string(name, enum: field.fetch('values'), description: description)
      when 'boolean'
        schema.boolean(name, description: description)
      when 'integer'
        schema.integer(name, description: description)
      end
    end
  end
end
