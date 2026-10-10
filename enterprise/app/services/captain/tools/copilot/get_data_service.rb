class Captain::Tools::Copilot::GetDataService < Captain::Tools::Copilot::WorkflowTool
  RESOURCES_HELP = Captain::Copilot::Resources.all.map(&:help).join("\n")

  def self.name
    'get_data'
  end
  description 'Select records with database filters and save them as a collection. Returns the collection ID and counts, not the records. ' \
              'Pass from to select the records linked to an earlier collection, or to the matched conversations of a finished review. ' \
              "Resources:\n#{RESOURCES_HELP}"
  parameters type: 'object', required: %w[resource filters], additionalProperties: false,
             properties: {
               resource: { type: 'string', enum: Captain::Copilot::Resources.all.map { |resource| resource::NAME } },
               filters: { type: 'object', description: 'Filters for the resource, as listed above' },
               from: { type: 'integer', description: 'ID of an earlier collection or finished review to start from' }
             }

  def execute(resource:, filters:, from: nil)
    Captain::Copilot::DataService.new(run, step: step, token: lease_token).retrieve(resource: resource, filters: filters, from: from)
  end
end
