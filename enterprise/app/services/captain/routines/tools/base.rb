require 'agents'

class Captain::Routines::Tools::Base < Agents::Tool
  REFERENCE_PATTERN = /\A[a-z][a-z0-9_]*\z/

  # ai-agents injects isolated execution state through ToolContext; tool instances hold no account state.
  # Source: https://github.com/chatwoot/ai-agents#custom-tools

  private

  def account(tool_context)
    account_id = tool_context.state[:account_id] || tool_context.state['account_id']
    Account.find(account_id)
  end

  def search_response(tool_context, reference:, query:, candidates:, exact_candidates:)
    return invalid_reference(reference) unless reference.match?(REFERENCE_PATTERN)

    resolved = resolved_candidate(exact_candidates, candidates)
    status = search_status(resolved, candidates)
    store_resource(tool_context, reference, resolved) if resolved

    {
      status: status,
      query: query,
      reference: reference,
      resource: resolved&.slice('type', 'id', 'name'),
      candidates: candidates
    }.to_json
  end

  def store_resource(tool_context, reference, candidate)
    resources = tool_context.state[:resolved_resources] ||= {}
    resource = candidate.slice('type', 'id', 'name')
    existing = resources[reference]
    raise ArgumentError, "Resource '#{reference}' was already resolved differently" if existing.present? && existing != resource

    resources[reference] = resource
  end

  def resolved_candidate(exact_candidates, candidates)
    return exact_candidates.first if exact_candidates.one?
    return candidates.first if candidates.one?
  end

  def search_status(resolved, candidates)
    return 'resolved' if resolved
    return 'not_found' if candidates.empty?

    'ambiguous'
  end

  def search_term(query)
    "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
  end

  def exact?(query, *values)
    values.compact.any? { |value| value.casecmp?(query) }
  end

  def invalid_reference(_reference)
    {
      status: 'invalid_reference',
      message: 'Reference must be stable snake_case beginning with a letter.'
    }.to_json
  end
end
