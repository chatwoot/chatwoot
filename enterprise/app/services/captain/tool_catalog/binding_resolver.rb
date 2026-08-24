class Captain::ToolCatalog::BindingResolver
  def initialize(provider_key:, model_input:, configuration:, state:, step_results:)
    @provider_key = provider_key
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

  attr_reader :provider_key, :sources, :step_results

  def resolve_binding(binding)
    source = binding.fetch('source')
    return binding.fetch('value') if source == 'literal'
    return fetch_path(step_results.fetch(binding.fetch('step')), binding.fetch('path')) if source == 'step_output'
    return shopify_contact_query if source == 'shopify_contact_query'
    return shopify_order_query(binding) if source == 'shopify_order_query'

    fetch_path(sources.fetch(source), binding.fetch('path'))
  rescue IndexError
    raise Captain::ToolCatalog::ExecutionError.new('validation', 'binding_unavailable')
  end

  def shopify_contact_query
    ensure_shopify!
    contact = sources.fetch('contact').to_h.with_indifferent_access
    terms = []
    terms << shopify_search_term('email', contact[:email]) if contact[:email].present?
    terms << shopify_search_term('phone', contact[:phone_number]) if contact[:phone_number].present?
    raise KeyError, 'contact identity' if terms.empty?

    terms.join(' OR ')
  end

  def shopify_order_query(binding)
    ensure_shopify!
    order_number = fetch_path(sources.fetch('model_input'), binding.fetch('path'))
    raise KeyError, 'order number' if order_number.blank?

    shopify_search_term('name', order_number.to_s.delete_prefix('#'))
  end

  def shopify_search_term(field, value)
    escaped = value.to_s.gsub(/["\\]/) { |character| "\\#{character}" }
    %(#{field}:"#{escaped}")
  end

  def ensure_shopify!
    raise KeyError, 'provider' unless provider_key == 'shopify'
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
