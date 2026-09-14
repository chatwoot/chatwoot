class Captain::Apropos::ExecutionFeedback
  MAX_TEXT = 320
  MAX_ITEMS = 8
  MAX_CALLS = 5
  MAX_ARGUMENT_BYTES = 2_000

  attr_accessor :stage, :location
  attr_reader :message

  def initialize
    @stage = 'parsing'
    @calls = []
  end

  def capture(error, expression, arguments = nil)
    # Preserve the innermost observation before higher-order primitives wrap the error.
    # A failing callback does not mean map or fold is broken. Shapes and surviving state
    # give the agent evidence to reconsider its approach without prescribing a repair or
    # copying customer data into its context. These observations never imply rollback.
    unless @message
      @message = error.message
      @expression = source(expression)
      if arguments
        @arguments = arguments.first(MAX_ITEMS).map { |value| shape(value) }
        @argument_count = arguments.length
      end
    end
    name = expression.is_a?(Array) ? expression.first : expression
    @calls = (@calls + [name.to_s]).uniq.first(MAX_CALLS) if name.is_a?(Symbol)
  end

  def render(error, runtime)
    {
      error: @message || error.message,
      evidence: evidence,
      context: {
        progress: runtime.execution_progress.merge(
          failed_binding_has_previous_value: runtime.scheme.bindings.key?(runtime.scheme.failed_binding.to_s.to_sym)
        ),
        receipts_ref: runtime.store(runtime.receipts), receipt_count: runtime.receipts.size,
        contracts: contracts(runtime.catalog),
        semantics: Captain::Apropos::Prompt.render(:execution_error)
      }
    }
  end

  def evidence
    lines = ["Stage: #{stage}."]
    lines << "Expression: #{@expression}" if @expression
    lines << "Call context (inner to outer): #{@calls.join(' -> ')}" if @calls.any?
    lines << "Evaluated arguments (#{@argument_count} total, bounded shapes): #{argument_shapes}" if @arguments
    lines << "Source location: #{JSON.generate(location)}" if location
    lines << 'No program expressions executed in this call.' if %w[parsing preflight].include?(stage)
    lines
  end

  private

  def argument_shapes
    JSON.generate(@arguments).byteslice(0, MAX_ARGUMENT_BYTES).scrub('')
  end

  def contracts(catalog)
    @calls.filter_map do |name|
      entry = catalog.entries[name]
      next unless entry

      { name: name }.merge(entry.slice(:signature, :description).transform_values { |text| bounded(text) })
    end
  end

  def bounded(text)
    text.to_s.byteslice(0, MAX_TEXT).scrub('')
  end

  def source(value, depth = 0)
    return '...' if depth >= 3

    case value
    when Array
      parts = value.first(MAX_ITEMS).map { |item| source(item, depth + 1) }
      parts << '...' if value.size > MAX_ITEMS
      bounded("(#{parts.join(' ')})")
    when Symbol then bounded(value)
    when String then bounded(JSON.generate(bounded(value)))
    when TrueClass, FalseClass then value ? '#t' : '#f'
    else bounded(value.inspect)
    end
  end

  def shape(value, depth = 0)
    info = Captain::Apropos::ContextLimits.describe(value)
    return info if depth >= 2

    if value.is_a?(Hash)
      info['fields'] = value.first(MAX_ITEMS).to_h.transform_keys { |key| bounded(key) }
                            .transform_values { |item| shape(item, depth + 1) }
    elsif value.is_a?(Array)
      info['sample_item_types'] = value.first(MAX_ITEMS).map { |item| item.class.name }.uniq
    end
    info
  end
end
