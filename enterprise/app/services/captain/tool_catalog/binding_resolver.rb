class Captain::ToolCatalog::BindingResolver
  def initialize(model_input:, configuration:, state:, step_results:)
    @sources = {
      'model_input' => model_input,
      'configuration' => configuration,
      'contact' => state.to_h[:contact] || state.to_h['contact'],
      'conversation' => state.to_h[:conversation] || state.to_h['conversation']
    }
    @step_results = step_results
  end

  def resolve(bindings)
    bindings.to_h.transform_values { |binding| resolve_binding(binding) }
  end

  private

  attr_reader :sources, :step_results

  def resolve_binding(binding)
    source = binding.fetch('source')
    return binding.fetch('value') if source == 'literal'
    return fetch_path(step_results.fetch(binding.fetch('step')), binding.fetch('path')) if source == 'step_output'

    fetch_path(sources.fetch(source), binding.fetch('path'))
  rescue IndexError
    raise Captain::ToolCatalog::ExecutionError.new('validation', 'binding_unavailable')
  end

  def fetch_path(value, path)
    path.split('.').reduce(value) do |current, segment|
      case current
      when Hash
        fetch_hash_value(current, segment)
      when Array
        index = Integer(segment, exception: false)
        raise KeyError, segment if index.nil? || index.negative?

        current.fetch(index)
      else
        raise KeyError, segment
      end
    end
  end

  def fetch_hash_value(value, key)
    return value.fetch(key) if value.key?(key)
    return value.fetch(key.to_sym) if value.key?(key.to_sym)

    raise KeyError, key
  end
end
