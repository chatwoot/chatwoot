class Captain::Apropos::Prompt
  ROOT = Rails.root.join('enterprise/app/views/captain/apropos/prompts').freeze
  PARTS = {
    coordinator: %w[foundation coordinator planning data_model language retrieval reasoning library actions recovery workspace coverage presentation],
    query: %w[foundation data_model query_role],
    reason: %w[foundation reason_role],
    execution_error: %w[execution_error],
    query_error: %w[query_error]
  }.freeze

  def self.parts(role, variables = {})
    PARTS.fetch(role).to_h do |name|
      template = Liquid::Template.parse(ROOT.join("#{name}.liquid").read, error_mode: :strict)
      [name, template.render!(variables, strict_variables: true, strict_filters: true).strip]
    end
  end

  def self.render(role, variables = {})
    parts(role, variables).values.join("\n\n")
  end

  def self.context(account:, budget:, depth:)
    {
      account_id: account.id, current_time_utc: Time.current.utc.iso8601,
      agent_calls_remaining: [Captain::Apropos::Runtime::MAX_AGENT_CALLS - budget.fetch(:calls), 0].max,
      query_calls_remaining: [Captain::Apropos::Query::MAX_CALLS - budget.fetch(:queries), 0].max,
      delegation_depth: depth
    }
  end
end
