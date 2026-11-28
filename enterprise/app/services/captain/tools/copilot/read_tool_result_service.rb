class Captain::Tools::Copilot::ReadToolResultService < Captain::Tools::Copilot::WorkflowTool
  MAX_ITEMS = 100
  # Below the view's limit, so a part with its counts and escaped line breaks still reaches the model whole.
  PART_LIMIT = Captain::Copilot::ToolResultView::LIMIT * 9 / 10
  MAX_COUNTS = 100
  OPERATORS = %w[equals not_equals one_of empty not_empty].freeze

  def self.name
    'read_tool_result'
  end
  description 'Read a saved tool result by its result_id, when the result was too large to show or was left out to save room. ' \
              'Without other arguments, returns the result if it fits, or its outline. path names a list or object inside the ' \
              'result as dot-separated keys from the outline; a key that crosses a list reads that key from every item. On a ' \
              'list, where keeps the items that meet every condition, search keeps the items whose text contains it, fields ' \
              'keeps only those dot paths of each item, and count_by returns how many kept items have each value at a dot path ' \
              'instead of the items. A condition on a list field holds when any of its values meets it. Matching ignores case. ' \
              'On a text result, search keeps the lines that contain it, and offset counts lines. Results come back in parts; ' \
              'pass next_offset as offset to read the next part. Use count_by and total_matching for counts instead of counting items.'
  parameters type: 'object', required: %w[result_id], additionalProperties: false,
             properties: {
               result_id: { type: 'integer', description: 'The result_id of the saved result' },
               path: { type: 'string', description: 'Dot path to a list or object; leave out for the whole result' },
               where: {
                 type: 'array', description: 'Conditions an item must all meet',
                 items: {
                   type: 'object', required: %w[field operator], additionalProperties: false,
                   properties: {
                     field: { type: 'string', description: 'Dot path inside each item' },
                     operator: { type: 'string', enum: OPERATORS },
                     value: { type: 'string', description: 'For equals and not_equals' },
                     values: { type: 'array', items: { type: 'string' }, description: 'For one_of' }
                   }
                 }
               },
               search: { type: 'string', description: 'Text an item or line must contain' },
               fields: { type: 'array', items: { type: 'string' }, description: 'Dot paths to keep in each item' },
               count_by: { type: 'string', description: 'Dot path to count the kept items by' },
               offset: { type: 'integer', description: 'Items or lines to skip, from next_offset' }
             }

  # Offered whenever Copilot is, since any tool's result can be saved.
  def active?
    true
  end

  def execute(result_id:, **options)
    tool_call = CopilotToolCall.of_thread(run.copilot_thread_id).find_by(id: result_id)
    return { error: "No saved result with result_id #{result_id} in this thread" } if tool_call.nil? || tool_call.result.nil?

    data = Captain::Copilot::ToolResultView.parse(tool_call.result)
    data.is_a?(String) ? read_text(data, options) : read_data(data, options)
  end

  private

  def read_data(data, options)
    node = options[:path].present? ? dig(data, options[:path].split('.')) : data
    return object_view(node, options[:path]) unless node.is_a?(Array)

    kept = node.select { |item| keep?(item, options) }
    return counts(kept, options[:count_by]) if options[:count_by].present?

    list_part(kept, Array(options[:fields]), options[:offset].to_i)
  end

  def keep?(item, options)
    return false if options[:search].present? && !contains?(JSON.generate(item), options[:search])

    Array.wrap(options[:where]).all? { |condition| meets?(item, condition.to_h.with_indifferent_access) }
  end

  def meets?(item, condition)
    values = Array.wrap(dig(item, condition[:field].to_s.split('.'))).flatten
    case condition[:operator]
    when 'equals', 'one_of' then matches_any?(values, condition)
    when 'not_equals' then !matches_any?(values, condition)
    when 'empty' then values.all?(&:blank?)
    when 'not_empty' then values.any?(&:present?)
    else raise ArgumentError, "Unknown operator #{condition[:operator]}; use one of #{OPERATORS.join(', ')}"
    end
  end

  def matches_any?(values, condition)
    wanted = condition[:operator] == 'one_of' ? Array(condition[:values]) : [condition[:value]]
    values.any? { |value| wanted.any? { |each_wanted| same?(value, each_wanted) } }
  end

  def counts(kept, count_by)
    tally = kept.flat_map { |item| count_keys(dig(item, count_by.split('.'))) }.tally.sort_by { |_value, count| -count }
    { total_matching: kept.size, distinct_values: tally.size, counts: tally.first(MAX_COUNTS).to_h }
  end

  # A list field counts once for each of its values, and an item without a value is counted apart.
  def count_keys(value)
    values = Array.wrap(value).flatten.compact_blank
    if values.empty?
      ['(no value)']
    else
      values.map { |each_value| each_value.is_a?(String) ? each_value : JSON.generate(each_value) }
    end
  end

  def list_part(kept, fields, offset)
    items = []
    size = 0
    kept.drop(offset).each do |item|
      item = fields.index_with { |field| dig(item, field.split('.')) } if fields.any?
      size += JSON.generate(item).size
      break if items.any? && (size > PART_LIMIT || items.size >= MAX_ITEMS)

      items << item
    end
    next_offset = offset + items.size
    { total_matching: kept.size, offset: offset, returned: items.size, next_offset: next_offset < kept.size ? next_offset : nil,
      items: items }.compact
  end

  def object_view(node, path)
    return node if JSON.generate(node).size <= Captain::Copilot::ToolResultView::LIMIT

    { path: path, note: 'This part is too large to show whole. Name a deeper path or a list inside it.',
      outline: Captain::Copilot::ToolResultView.outline(node) }
  end

  def read_text(text, options)
    lines = text.lines
    lines = lines.select { |line| contains?(line, options[:search]) } if options[:search].present?
    offset = options[:offset].to_i
    part = lines.drop(offset).each_with_object(+'') do |line, buffer|
      break buffer if buffer.size + line.size > PART_LIMIT && buffer.present?

      buffer << line
    end
    next_offset = offset + part.lines.size
    { total_lines: lines.size, offset: offset, next_offset: next_offset < lines.size ? next_offset : nil,
      text: part.first(PART_LIMIT) }.compact
  end

  def contains?(text, search)
    text.downcase.include?(search.to_s.downcase)
  end

  def same?(value, wanted)
    value.to_s.casecmp?(wanted.to_s)
  end

  def dig(value, keys)
    return value if keys.empty?

    key, *rest = keys
    case value
    when Hash then dig(value[key], rest)
    when Array then key.match?(/\A\d+\z/) ? dig(value[key.to_i], rest) : value.map { |item| dig(item, keys) }
    end
  end
end
