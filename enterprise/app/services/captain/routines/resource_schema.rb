class Captain::Routines::ResourceSchema
  RESOURCE = {
    'type' => 'object',
    'required' => %w[type id name],
    'additionalProperties' => false,
    'properties' => {
      'type' => { 'enum' => %w[agent team inbox label] },
      'id' => { 'type' => 'integer', 'minimum' => 1 },
      'name' => { 'type' => 'string', 'minLength' => 1 }
    }
  }.freeze

  COLLECTION = {
    'type' => 'object',
    'propertyNames' => { 'pattern' => '^[a-z][a-z0-9_]*$' },
    'additionalProperties' => RESOURCE
  }.freeze
end
