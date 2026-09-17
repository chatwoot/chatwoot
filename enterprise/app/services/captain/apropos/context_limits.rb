class Captain::Apropos::ContextLimits
  TOOL_BYTES = 8_000
  REASON_INPUT_BYTES = 16_000
  HISTORY_BYTES = 24_000
  # This bounds accumulated runner history, not only the current prompt or tool result. See RequestBudget for the compaction limitation.
  REQUEST_BYTES = 120_000
  PREVIEW_ITEMS = 3
  PREVIEW_STRING_BYTES = 300
  PREVIEW_DEPTH = 3

  def self.describe(value)
    { 'type' => value.class.name, 'size' => value.respond_to?(:size) ? value.size : nil }
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
