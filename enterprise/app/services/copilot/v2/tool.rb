class Copilot::V2::Tool < RubyLLM::Tool
  STRING = { type: 'string' }.freeze
  STRINGS = { type: 'array', items: STRING, maxItems: 30 }.freeze
  NULL_STRING = { anyOf: [STRING, { type: 'null' }] }.freeze
  VALUE = { anyOf: [STRING, { type: 'integer' }, { type: 'number' }, { type: 'boolean' }, { type: 'null' }, STRINGS,
                    { type: 'array', items: { type: 'integer' } }] }.freeze
  FILTERS = { type: 'array', maxItems: 10, items: { type: 'object', additionalProperties: false,
                                                    properties: { field: STRING, operator: { type: 'string', enum: %w[eq in gte lte contains] },
                                                                  value: VALUE },
                                                    required: %w[field operator value] } }.freeze
  WINDOW = { anyOf: [{ type: 'null' }, { type: 'object', additionalProperties: false,
                                         properties: { since: STRING, until: STRING }, required: %w[since until] }] }.freeze
  FIELDS = { type: 'array', maxItems: 10, items: { type: 'object', additionalProperties: false,
                                                   properties: { name: STRING, type: { type: 'string', enum: %w[string integer number boolean] },
                                                                 values: STRINGS },
                                                   required: %w[name type values] } }.freeze
  CONTRACTS = {
    'resource_catalog' => {},
    'select_resources' => { resource: STRING, fields: { anyOf: [STRINGS, { type: 'null' }] }, filters: FILTERS,
                            order: { type: 'string', enum: %w[oldest newest oldest_waiting] },
                            limit: { anyOf: [{ type: 'integer', minimum: 1 }, { type: 'null' }] }, personal: NULL_STRING, mention_window: WINDOW },
    'read_related' => { selection_ref: STRING, relationship: STRING, fields: { anyOf: [STRINGS, { type: 'null' }] },
                        filters: FILTERS, window: WINDOW, customer_only: { type: 'boolean' } },
    'analyze_records' => { evidence_ref: STRING, mode: { type: 'string', enum: %w[classify extract summarize] },
                           instruction: { type: 'string', minLength: 1, maxLength: 10_000 }, fields: FIELDS },
    'aggregate_results' => { result_ref: STRING, group_by: STRINGS, unit: { type: 'string', enum: %w[records customers] } },
    'show_results' => { result_ref: STRING, supersedes_ref: NULL_STRING }
  }.freeze
  DESCRIPTIONS = {
    'resource_catalog' => 'Discover allowed resources, typed fields, filters, and relationships.',
    'select_resources' => 'Capture an authorized fixed selection. Null limit means all matching up to the disclosed server cap.',
    'read_related' => 'Capture complete related evidence per selected parent. Omitted window defaults to seven days for messages.',
    'analyze_records' => 'Classify, extract or summarize stored text evidence. Ruby owns batches, citations, retries and coverage. ' \
                         'Conversation semantics require message evidence. Every row already includes record_id, ' \
                         'decision (match/no_match/uncertain), reason and citations. Fields are additional extracted values; ' \
                         'use [] for summary or simple matching. Reserved field names: record_id, decision, reason, citations, count, coverage. ' \
                         'Enum values are allowed only for string fields; use values: [] for other types.',
    'aggregate_results' => 'Compute counts in Ruby from stored results or selected rows. ' \
                           'Customers counts distinct contact IDs, never conversations. ' \
                           'Group analysis by decision to count matches separately; group_by: [] counts all resolved rows.',
    'show_results' => 'Read and publish captured rows from a selection, analysis result, or aggregate reference. ' \
                      'Publish selections directly for lookups and calculated reports. ' \
                      'Evidence references cannot be published; analyze them first. ' \
                      'Only published references are authoritative output.'
  }.freeze

  def initialize(name)
    super()
    @name = name
  end

  attr_reader :name

  def description
    DESCRIPTIONS.fetch(name)
  end

  def params_schema
    properties = CONTRACTS.fetch(name)
    { type: 'object', properties: properties, required: properties.keys.map(&:to_s), additionalProperties: false }
  end

  def execute(**arguments)
    halt(arguments.to_json)
  end

  def self.validate!(name, arguments)
    schema = new(name).params_schema.deep_stringify_keys
    raise ArgumentError, 'Invalid typed operation arguments' unless JSONSchemer.schema(schema).valid?(arguments)
  end
end
