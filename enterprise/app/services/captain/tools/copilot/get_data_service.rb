class Captain::Tools::Copilot::GetDataService < Captain::Tools::Copilot::WorkflowTool
  def self.name
    'get_data'
  end
  description 'Select records with database filters and save them as a collection. Returns the collection ID, total (the exact number ' \
              'of matching records) and the first and last dates of the matching records. Does not return the records. ' \
              'Pass from to select the records linked to an earlier collection or to the matched conversations of a finished review, ' \
              'and exclude_from to keep only the records not linked to one; any two linked resources can be chained this way. ' \
              'Inside filters, every resource takes since and before, date_field (any of its date columns), newest, oldest_first, ' \
              'sample (that many records spread evenly across the matching set), a column name for its value (null for no value), ' \
              'empty and not_empty (lists of columns, keys inside JSON columns, resources that point at this one, or labels, ' \
              'that must have no value or a value), at_least and at_most (bounds on numeric columns), and attributes (values of ' \
              "keys inside JSON columns, written column.key). Pass describe for one resource's allowed values, the keys its records " \
              'use inside JSON columns and the resources it can start from.'
  parameters type: 'object', required: %w[resource], additionalProperties: false,
             properties: {
               resource: { type: 'string', description: 'One of the resources listed in the description' },
               filters: { type: 'object', description: 'Filters for the resource, as listed in the description' },
               from: { type: 'integer', description: 'ID of an earlier collection or finished review to start from' },
               exclude_from: { type: 'integer', description: 'ID of an earlier collection or finished review; keep only records not linked to it' },
               group_by: { type: 'string',
                           description: 'Count the matching records per period of date_field (day, week, month or year) or per field, ' \
                                        'as aggregate group_by takes it. Records without a value are counted apart in without_value' },
               aggregate: {
                 type: 'object', required: %w[measure], additionalProperties: false,
                 description: 'Measure the matching records in the database instead of only counting them',
                 properties: {
                   measure: { type: 'string', enum: Captain::Copilot::Aggregation::MEASURES },
                   column: { type: 'string', description: 'Numeric column for sum, average, median, minimum or maximum' },
                   duration: { type: 'array', items: { type: 'string' }, minItems: 2, maxItems: 2,
                               description: 'Two date columns; measures the time from the first to the second, in hours' },
                   group_by: { type: 'array', items: { type: 'string' }, maxItems: 2,
                               description: 'Up to two fields: a period of date_field, a column or its association name, a key inside ' \
                                            'a JSON column written column.key, label, a group the resource lists, or a date column ' \
                                            'with a part, written column:part with part one of ' \
                                            "#{Captain::Copilot::Aggregation::DATE_PARTS.keys.join(', ')}" }
                 }
               },
               chart: { type: 'boolean', description: 'Only when the agent asks for a graph or chart of group_by or a one-field aggregate' },
               describe: { type: 'boolean', description: "Return the resource's filters, JSON keys and sources instead of selecting" }
             }

  # RubyLLM reads the description on every model call, and the tool is built for each turn.
  def description
    @description ||= begin
      resources = Captain::Copilot::Resources.readable(account: run.account, user: run.user)
      "#{self.class.description} Resources:\n#{resources.map(&:help).join("\n")}"
    end
  end

  def execute(resource:, filters: {}, from: nil, **options)
    return Captain::Copilot::Resources.build(resource, account: run.account, user: run.user).describe if options[:describe]

    Captain::Copilot::CollectionService.new(run, tool_call: tool_call, token: lease_token)
                                       .create(resource: resource, filters: filters, from: from, **options.slice(:exclude_from, :group_by,
                                                                                                                 :aggregate, :chart))
  end
end
