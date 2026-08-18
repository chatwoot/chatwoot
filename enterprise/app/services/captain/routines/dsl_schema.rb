class Captain::Routines::DslSchema
  SCHEMA = {
    'type' => 'object',
    'required' => %w[version kind name steps],
    'additionalProperties' => false,
    'properties' => {
      'version' => { 'const' => 1 },
      'kind' => { 'const' => 'captain.routine' },
      'name' => { 'type' => 'string', 'minLength' => 1 },
      'resources' => Captain::Routines::ResourceSchema::COLLECTION,
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
      'selection' => {
        'type' => 'object',
        'required' => %w[select where],
        'additionalProperties' => false,
        'properties' => {
          'select' => { 'const' => 'conversations' },
          'where' => { 'type' => 'object' }
        }
      },
      'result_field' => {
        'type' => 'object',
        'required' => %w[name type description values],
        'additionalProperties' => false,
        'properties' => {
          'name' => { 'type' => 'string', 'pattern' => '^[a-z][a-z0-9_]*$' },
          'type' => { 'enum' => %w[string string_list enum boolean integer] },
          'description' => { 'type' => 'string', 'minLength' => 1 },
          'values' => {
            'type' => 'array',
            'maxItems' => 20,
            'uniqueItems' => true,
            'items' => { 'type' => 'string', 'pattern' => '^[a-z][a-z0-9_]*$' }
          }
        }
      },
      'result_contract' => {
        'type' => 'object',
        'required' => %w[outcomes fields],
        'additionalProperties' => false,
        'properties' => {
          'outcomes' => {
            'type' => 'array',
            'minItems' => 1,
            'maxItems' => 12,
            'uniqueItems' => true,
            'items' => { 'type' => 'string', 'pattern' => '^[a-z][a-z0-9_]*$' }
          },
          'fields' => {
            'type' => 'array',
            'maxItems' => 10,
            'items' => { '$ref' => '#/definitions/result_field' }
          }
        }
      },
      'record_agent' => {
        'type' => 'object',
        'required' => %w[agent instruction result],
        'additionalProperties' => false,
        'properties' => {
          'agent' => { 'const' => 'captain' },
          'instruction' => { 'type' => 'string', 'minLength' => 1 },
          'result' => { '$ref' => '#/definitions/result_contract' }
        }
      },
      'reducer_agent' => {
        'type' => 'object',
        'required' => %w[agent instruction],
        'additionalProperties' => false,
        'properties' => {
          'agent' => { 'const' => 'captain' },
          'instruction' => { 'type' => 'string', 'minLength' => 1 }
        }
      },
      'each_step' => {
        'type' => 'object',
        'required' => %w[each from run collect_as],
        'additionalProperties' => false,
        'properties' => {
          'each' => { 'type' => 'string', 'pattern' => '^[a-z][a-z0-9_]*$' },
          'from' => { '$ref' => '#/definitions/selection' },
          'run' => { '$ref' => '#/definitions/record_agent' },
          'collect_as' => { 'type' => 'string', 'pattern' => '^[a-z][a-z0-9_]*$' }
        }
      },
      'reduce_step' => {
        'type' => 'object',
        'required' => %w[reduce run save_as],
        'additionalProperties' => false,
        'properties' => {
          'reduce' => { '$ref' => '#/definitions/reference' },
          'run' => { '$ref' => '#/definitions/reducer_agent' },
          'save_as' => { 'type' => 'string', 'pattern' => '^[a-z][a-z0-9_]*$' }
        }
      },
      'step' => {
        'oneOf' => %w[each_step reduce_step].map do |definition|
          { '$ref' => "#/definitions/#{definition}" }
        end
      }
    }
  }.freeze

  class << self
    def errors(dsl)
      Captain::Routines::DslValidator.new(dsl).errors
    end

    def valid?(dsl)
      errors(dsl).empty?
    end

    def prompt
      JSON.pretty_generate(SCHEMA)
    end
  end
end
