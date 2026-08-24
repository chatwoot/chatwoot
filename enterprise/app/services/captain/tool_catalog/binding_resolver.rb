class Captain::ToolCatalog::BindingResolver
  SPECIAL_BINDING_SOURCES = %w[literal step_output shopify_contact_query shopify_order_query linear_conversation_url linear_linked_issue_id].freeze

  def initialize(provider_key:, model_input:, configuration:, state:, step_results:)
    @provider_key = provider_key
    @account_id = state.to_h[:account_id] || state.to_h['account_id']
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

  attr_reader :provider_key, :account_id, :sources, :step_results

  def resolve_binding(binding)
    source = binding.fetch('source')
    return resolve_special_binding(source, binding) if SPECIAL_BINDING_SOURCES.include?(source)

    fetch_path(sources.fetch(source), binding.fetch('path'))
  rescue IndexError
    raise Captain::ToolCatalog::ExecutionError.new('validation', 'binding_unavailable')
  end

  def resolve_special_binding(source, binding)
    case source
    when 'literal' then binding.fetch('value')
    when 'step_output' then fetch_path(step_results.fetch(binding.fetch('step')), binding.fetch('path'))
    when 'shopify_contact_query' then shopify_contact_query
    when 'shopify_order_query' then shopify_order_query(binding)
    when 'linear_conversation_url' then linear_conversation_url
    when 'linear_linked_issue_id' then linear_linked_issue_id(binding)
    end
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

  def linear_conversation_url
    ensure_linear!
    frontend_url = ENV.fetch('FRONTEND_URL', nil).to_s.delete_suffix('/')
    display_id = sources.fetch('conversation').to_h.with_indifferent_access[:display_id]
    raise KeyError, 'conversation identity' if frontend_url.blank? || account_id.blank? || display_id.blank?

    "#{frontend_url}/app/accounts/#{account_id}/conversations/#{display_id}"
  end

  def linear_linked_issue_id(binding)
    ensure_linear!
    identifier = fetch_path(sources.fetch('model_input'), binding.fetch('path')).to_s
    issue = linked_issues(binding).find do |candidate|
      candidate.to_h.with_indifferent_access[:identifier].to_s.casecmp?(identifier)
    end
    issue.to_h.with_indifferent_access.fetch(:id)
  end

  def linked_issues(binding)
    nodes = fetch_path(step_results.fetch(binding.fetch('step')), 'attachmentsForURL.nodes')
    raise KeyError, 'linked issues' unless nodes.is_a?(Array)

    nodes.filter_map { |attachment| attachment.to_h['issue'] || attachment.to_h[:issue] }
  end

  def ensure_linear!
    raise KeyError, 'provider' unless provider_key == 'linear'
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
