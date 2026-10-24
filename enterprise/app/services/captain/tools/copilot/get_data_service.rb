class Captain::Tools::Copilot::GetDataService < Captain::Tools::Copilot::WorkflowTool
  RESOURCES_HELP = Captain::Copilot::Resources.all.map(&:help).join("\n")

  def self.name
    'get_data'
  end
  description 'Select records with database filters and save them as a collection. Returns the collection ID, total (the exact number ' \
              'of matching records) and, with group_by, the exact count per group. Does not return the records. ' \
              'Pass from to select the records linked to an earlier collection, or to the matched conversations of a finished review. ' \
              "Resources:\n#{RESOURCES_HELP}"
  parameters type: 'object', required: %w[resource filters], additionalProperties: false,
             properties: {
               resource: { type: 'string', enum: Captain::Copilot::Resources.all.map { |resource| resource::NAME } },
               filters: { type: 'object', description: 'Filters for the resource, as listed above' },
               from: { type: 'integer', description: 'ID of an earlier collection or finished review to start from' },
               group_by: { type: 'string',
                           description: 'Count the matching records per period of date_field (day, week, month or year, in UTC) ' \
                                        'or per value, as listed above for the resource' }
             }

  def execute(resource:, filters:, from: nil, group_by: nil)
    Captain::Copilot::CollectionService.new(run, tool_call: tool_call, token: lease_token).create(resource: resource, filters: filters, from: from,
                                                                                                  group_by: group_by)
  end
end
