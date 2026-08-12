class Captain::Routines::DslSchema
  SCHEMA = {
    'type' => 'object',
    'required' => %w[version kind name trigger steps],
    'additionalProperties' => false,
    'properties' => {
      'version' => { 'const' => 1 },
      'kind' => { 'const' => 'captain.routine' },
      'name' => { 'type' => 'string', 'minLength' => 1 },
      'trigger' => {
        'type' => 'object',
        'required' => ['type'],
        'additionalProperties' => false,
        'properties' => {
          'type' => { 'enum' => %w[manual schedule event] },
          'schedule' => { 'type' => 'string', 'minLength' => 1 },
          'event' => { 'type' => 'string', 'minLength' => 1 }
        }
      },
      'steps' => {
        'type' => 'array',
        'minItems' => 1,
        'items' => { '$ref' => '#/definitions/step' }
      }
    },
    'definitions' => {
      'reference' => {
        'type' => 'object',
        'required' => ['ref'],
        'additionalProperties' => false,
        'properties' => { 'ref' => { 'type' => 'string', 'minLength' => 1 } }
      },
      'source' => {
        'type' => 'object',
        'required' => %w[tool with],
        'additionalProperties' => false,
        'properties' => {
          'tool' => { 'type' => 'string', 'minLength' => 1 },
          'with' => { 'type' => 'object' }
        }
      },
      'condition' => {
        'type' => 'object',
        'required' => %w[ref equals],
        'additionalProperties' => false,
        'properties' => {
          'ref' => { 'type' => 'string', 'minLength' => 1 },
          'equals' => {}
        }
      },
      'each_step' => {
        'type' => 'object',
        'required' => %w[each from do],
        'additionalProperties' => false,
        'properties' => {
          'each' => { 'type' => 'string', 'minLength' => 1 },
          'from' => { '$ref' => '#/definitions/source' },
          'do' => {
            'type' => 'array',
            'minItems' => 1,
            'items' => { '$ref' => '#/definitions/step' }
          }
        }
      },
      'tool_step' => {
        'type' => 'object',
        'required' => %w[tool with],
        'additionalProperties' => false,
        'properties' => {
          'tool' => { 'type' => 'string', 'minLength' => 1 },
          'with' => { 'type' => 'object' }
        }
      },
      'decide_step' => {
        'type' => 'object',
        'required' => %w[decide about choices],
        'additionalProperties' => false,
        'properties' => {
          'decide' => { 'type' => 'string', 'minLength' => 1 },
          'about' => { '$ref' => '#/definitions/reference' },
          'instruction' => { 'type' => 'string', 'minLength' => 1 },
          'choices' => {
            'type' => 'array',
            'minItems' => 2,
            'uniqueItems' => true,
            'items' => { 'type' => 'string', 'minLength' => 1 }
          }
        }
      },
      'when_step' => {
        'type' => 'object',
        'required' => %w[when do],
        'additionalProperties' => false,
        'properties' => {
          'when' => { '$ref' => '#/definitions/condition' },
          'do' => {
            'type' => 'array',
            'minItems' => 1,
            'items' => { '$ref' => '#/definitions/step' }
          },
          'else' => {
            'type' => 'array',
            'minItems' => 1,
            'items' => { '$ref' => '#/definitions/step' }
          }
        }
      },
      'approval_step' => {
        'type' => 'object',
        'required' => %w[approval context],
        'additionalProperties' => false,
        'properties' => {
          'approval' => { 'type' => 'string', 'minLength' => 1 },
          'context' => { 'type' => 'object' },
          'do' => { 'type' => 'array', 'minItems' => 1, 'items' => { '$ref' => '#/definitions/step' } }
        }
      },
      'step' => {
        'oneOf' => %w[each_step tool_step decide_step when_step approval_step].map do |definition|
          { '$ref' => "#/definitions/#{definition}" }
        end
      }
    }
  }.freeze

  class << self
    def errors(dsl)
      schema_errors(dsl) + tool_errors(dsl)
    end

    def valid?(dsl)
      errors(dsl).empty?
    end

    def prompt
      JSON.pretty_generate(SCHEMA)
    end

    private

    def schema_errors(dsl)
      JSONSchemer.schema(SCHEMA).validate(dsl).map do |error|
        path = error['data_pointer'].presence || '/'
        "#{path}: #{error['type']} #{error['details'].to_json}"
      end
    end

    def tool_errors(dsl)
      return [] unless dsl.is_a?(Hash)

      validate_steps(dsl['steps'])
    end

    def validate_steps(steps)
      Array(steps).flat_map do |step|
        next [] unless step.is_a?(Hash)

        errors = validate_step_tool(step)
        errors.concat(validate_steps(step['do']))
        errors.concat(validate_steps(step['else']))
        errors
      end
    end

    def validate_step_tool(step)
      if step['from'].is_a?(Hash)
        validate_tool(step['from']['tool'], step['from']['with'], kind: 'source')
      elsif step['tool'].present?
        validate_tool(step['tool'], step['with'], kind: 'action')
      else
        []
      end
    end

    def validate_tool(name, arguments, kind:)
      catalog = Captain::Routines::ToolCatalog
      return ["Tool '#{name}' is not an available #{kind}"] unless catalog.include?(name, kind: kind)

      tool = catalog.fetch(name)
      argument_names = arguments.is_a?(Hash) ? arguments.keys : []
      missing_arguments = tool[:required] - argument_names
      unknown_arguments = argument_names - tool[:arguments].keys.map(&:to_s)

      missing_arguments.map { |argument| "Tool '#{name}' is missing required argument '#{argument}'" } +
        unknown_arguments.map { |argument| "Tool '#{name}' does not accept argument '#{argument}'" }
    end
  end
end
