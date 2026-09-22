class Copilot::V2::ResultValidator
  RESERVED = %w[record_id decision reason citations count coverage].freeze

  def initialize(specification) # rubocop:disable Metrics/CyclomaticComplexity
    @specification = specification
    fields = specification.fetch('fields')
    names = fields.pluck('name')
    raise ArgumentError, 'Duplicate or reserved result fields' if names.uniq != names || names.intersect?(RESERVED)
    raise ArgumentError, 'Invalid field name' unless names.all? { |name| name.match?(/\A[a-z][a-z0-9_]{0,39}\z/) }
    raise ArgumentError, 'Enums require string fields' if fields.any? { |field| field['values'].any? && field['type'] != 'string' }
  end

  def schema
    values = @specification.fetch('fields').to_h do |field|
      definition = { type: field.fetch('type') }
      definition[:enum] = field['values'] if field['values'].any?
      [field.fetch('name'), { anyOf: [definition, { type: 'null' }] }]
    end
    citation = object({ record_id: { anyOf: [{ type: 'integer' }, { type: 'string' }],
                                     description: 'Source evidence[].id, such as the message ID. Not the parent record_id.' },
                        part_id: { type: 'string', description: 'Exact parts[].id belonging to that source evidence entry.' } })
    row = object({ record_id: { anyOf: [{ type: 'integer' }, { type: 'string' }], description: 'Exact top-level input record_id.' },
                   decision: { type: 'string', enum: %w[match no_match uncertain] },
                   reason: { type: 'string', minLength: 1 }, values: object(values),
                   citations: { type: 'array', items: citation } })
    object({ results: { type: 'array', items: row } })
  end

  def validate!(output, inputs) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
    raise ArgumentError, 'Malformed analysis result' unless JSONSchemer.schema(schema.deep_stringify_keys).valid?(output)

    rows = output.fetch('results')
    raise ArgumentError, 'Expected every supplied identity exactly once' unless rows.pluck('record_id').sort == inputs.pluck('record_id').sort

    rows.each do |row|
      input = inputs.find { |item| item['record_id'] == row['record_id'] }
      allowed = input.fetch('evidence').flat_map do |record|
        Array(record['parts']).filter_map do |part|
          { 'record_id' => record.fetch('id'), 'part_id' => part.fetch('id') } if part['text'].present?
        end
      end
      citations = row.fetch('citations')
      raise ArgumentError, 'Duplicate or foreign evidence citations' unless citations.uniq == citations && (citations - allowed).empty?
      raise ArgumentError, 'Positive finding requires supporting citations' if row['decision'] == 'match' && citations.empty?
      if @specification['mode'] != 'classify' && row.fetch('values').values.any? { |value| !value.nil? } && citations.empty?
        raise ArgumentError, 'Extracted facts require supporting citations'
      end
      raise ArgumentError, 'No textual evidence requires uncertainty' if allowed.empty? && row['decision'] != 'uncertain'
      if input.fetch('limitations').any? && row['decision'] == 'no_match'
        raise ArgumentError, 'Incomplete source content cannot establish a negative finding; use uncertain'
      end
    end
    rows
  end

  private

  def object(properties)
    { type: 'object', properties: properties, required: properties.keys.map(&:to_s), additionalProperties: false }
  end
end
