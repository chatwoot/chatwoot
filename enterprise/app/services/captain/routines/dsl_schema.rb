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
      'collection_query' => {
        'oneOf' => [
          { '$ref' => '#/definitions/reference' },
          {
            'type' => 'object',
            'required' => %w[operation with],
            'additionalProperties' => false,
            'properties' => {
              'operation' => { 'type' => 'string', 'minLength' => 1 },
              'with' => { 'type' => 'object' }
            }
          }
        ]
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
          'from' => { '$ref' => '#/definitions/collection_query' },
          'do' => {
            'type' => 'array',
            'minItems' => 1,
            'items' => { '$ref' => '#/definitions/step' }
          }
        }
      },
      'operation_step' => {
        'type' => 'object',
        'required' => %w[operation with],
        'additionalProperties' => false,
        'properties' => {
          'operation' => { 'type' => 'string', 'minLength' => 1 },
          'with' => { 'type' => 'object' },
          'save_as' => { 'type' => 'string', 'minLength' => 1 }
        }
      },
      'decide_step' => {
        'type' => 'object',
        'required' => %w[decide choices],
        'additionalProperties' => false,
        'properties' => {
          'decide' => { 'type' => 'string', 'minLength' => 1 },
          'about' => { '$ref' => '#/definitions/reference' },
          'context' => {
            'type' => 'object',
            'minProperties' => 1,
            'additionalProperties' => { '$ref' => '#/definitions/reference' }
          },
          'instruction' => { 'type' => 'string', 'minLength' => 1 },
          'choices' => {
            'type' => 'array',
            'minItems' => 2,
            'uniqueItems' => true,
            'items' => { 'type' => 'string', 'minLength' => 1 }
          }
        },
        'anyOf' => [
          { 'required' => ['about'] },
          { 'required' => ['context'] }
        ]
      },
      'compose_step' => {
        'type' => 'object',
        'required' => %w[compose instruction context],
        'additionalProperties' => false,
        'properties' => {
          'compose' => { 'type' => 'string', 'minLength' => 1 },
          'instruction' => { 'type' => 'string', 'minLength' => 1 },
          'context' => {
            'type' => 'object',
            'minProperties' => 1,
            'additionalProperties' => { '$ref' => '#/definitions/reference' }
          },
          'mention_bindings' => {
            'type' => 'object',
            'minProperties' => 1,
            'additionalProperties' => { '$ref' => '#/definitions/reference' }
          },
          'required_mentions' => {
            'type' => 'array',
            'minItems' => 1,
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
      'step' => {
        'oneOf' => %w[each_step operation_step decide_step compose_step when_step].map do |definition|
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
