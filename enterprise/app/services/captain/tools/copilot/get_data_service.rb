class Captain::Tools::Copilot::GetDataService < Captain::Tools::Copilot::WorkflowTool
  def self.name
    'get_data'
  end
  description 'Retrieve an authorized collection of conversations using database filters. Returns a saved collection ID, not message bodies.'
  parameters type: 'object', required: %w[resource filters], additionalProperties: false,
             properties: { resource: { type: 'string', enum: ['conversations'] }, filters: Captain::Copilot::DataService::FILTER_SCHEMA }

  def execute(resource:, filters:)
    Captain::Copilot::DataService.new(run, step: step, token: lease_token).retrieve(resource: resource, filters: filters)
  end
end
