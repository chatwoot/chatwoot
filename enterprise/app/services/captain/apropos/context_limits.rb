class Captain::Apropos::ContextLimits
  TOOL_BYTES = 8_000
  REASON_INPUT_BYTES = 900_000
  HISTORY_BYTES = 500_000
  # This bounds accumulated runner history, not only the current prompt or tool result. See RequestBudget for the compaction limitation.
  REQUEST_BYTES = 1_000_000
  PREVIEW_ITEMS = 3
  PREVIEW_STRING_BYTES = 300
  PREVIEW_DEPTH = 3

  def self.describe(value)
    case value
    when Array then { 'type' => 'list', 'item_count' => value.size }
    when Hash then { 'type' => 'object', 'field_count' => value.size }
    when String then { 'type' => 'string', 'character_count' => value.length }
    when Integer then { 'type' => 'integer' }
    when Numeric then { 'type' => 'number' }
    when TrueClass, FalseClass then { 'type' => 'boolean' }
    when NilClass then { 'type' => 'null' }
    when ::Scheme::Pair then { 'type' => 'list', 'item_count' => ::Scheme.to_a(value).size }
    else
      return { 'type' => 'list', 'item_count' => 0 } if value.equal?(::Scheme::EMPTY)

      { 'type' => Captain::Apropos::SchemeValues.procedure?(value) ? 'procedure' : 'scheme_value' }
    end
  rescue ::Scheme::Error
    { 'type' => 'pair' }
  end

  def self.preview(value, depth = 0)
    return describe(value) if depth >= PREVIEW_DEPTH

    case value
    when Hash then value.first(PREVIEW_ITEMS).to_h.transform_values { |item| preview(item, depth + 1) }
    when Array then value.first(PREVIEW_ITEMS).map { |item| preview(item, depth + 1) }
    when String then value.byteslice(0, PREVIEW_STRING_BYTES).scrub('')
    else value
    end
  end
end
