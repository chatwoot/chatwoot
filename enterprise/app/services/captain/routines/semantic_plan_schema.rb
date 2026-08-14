class Captain::Routines::SemanticPlanSchema
  SCHEMA = {
    'type' => 'object',
    'required' => %w[version name steps],
    'additionalProperties' => false,
    'properties' => {
      'version' => { 'const' => 1 },
      'name' => { 'type' => 'string', 'minLength' => 1 },
      'resources' => Captain::Routines::ResourceSchema::COLLECTION,
      'steps' => {
        'type' => 'array',
        'minItems' => 1,
        'items' => { '$ref' => '#/definitions/step' }
      }
    },
    'definitions' => {
      'step' => {
        'type' => 'object',
        'required' => %w[id type description],
        'additionalProperties' => false,
        'properties' => {
          'id' => { 'type' => 'string', 'pattern' => '^[a-z][a-z0-9_]*$' },
          'type' => { 'enum' => %w[selection context decision compose branch action constraint] },
          'description' => { 'type' => 'string', 'minLength' => 1 },
          'depends_on' => {
            'type' => 'array',
            'uniqueItems' => true,
            'items' => { 'type' => 'string', 'minLength' => 1 }
          },
          'choices' => {
            'type' => 'array',
            'minItems' => 2,
            'uniqueItems' => true,
            'items' => { 'type' => 'string', 'minLength' => 1 }
          },
          'condition' => { 'type' => 'string', 'minLength' => 1 },
          'steps' => {
            'type' => 'array',
            'minItems' => 1,
            'items' => { '$ref' => '#/definitions/step' }
          }
        },
        'allOf' => [
          {
            'if' => { 'properties' => { 'type' => { 'const' => 'decision' } } },
            'then' => { 'required' => ['choices'] }
          },
          {
            'if' => { 'properties' => { 'type' => { 'const' => 'compose' } } },
            'then' => { 'not' => { 'required' => ['choices'] } }
          },
          {
            'if' => { 'properties' => { 'type' => { 'const' => 'branch' } } },
            'then' => { 'required' => %w[condition steps] }
          }
        ]
      }
    }
  }.freeze

  class << self
    def errors(plan)
      JSONSchemer.schema(SCHEMA).validate(plan).map do |error|
        path = error['data_pointer'].presence || '/'
        "#{path}: #{error['type']} #{error['details'].to_json}"
      end
    end

    def valid?(plan)
      errors(plan).empty?
    end

    def prompt
      JSON.pretty_generate(SCHEMA)
    end
  end
end
