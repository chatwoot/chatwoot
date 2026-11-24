class SearchIndexing::ConversationFilterConditions
  include Filters::DateFilterHelper

  ID_FIELDS = %w[inbox_id assignee_id team_id].freeze
  DATE_FIELDS = %w[created_at last_activity_at].freeze
  JOIN_OPERATORS = %w[AND OR].freeze

  def initialize(payload)
    @payload = payload.map { |condition| condition.to_h.with_indifferent_access }
  end

  def query
    return if @payload.size > 50

    return unless @payload[0...-1].all? { |condition| JOIN_OPERATORS.include?(condition[:query_operator].to_s.upcase) }

    clauses = @payload.map { |condition| clause_for(condition) }
    return if clauses.any?(&:nil?)

    { bool: { should: grouped_clauses(clauses), minimum_should_match: 1 } }
  end

  private

  # SQL binds AND more tightly than OR. Each group is one conjunction.
  def grouped_clauses(clauses)
    groups = [[]]
    @payload.zip(clauses).each do |condition, clause|
      groups.last << clause
      groups << [] if condition[:query_operator].to_s.casecmp('or').zero?
    end
    groups.map { |group| { bool: { filter: group } } }
  end

  def clause_for(condition)
    field = condition[:attribute_key]
    return date_clause(condition) if DATE_FIELDS.include?(field)
    return unless (ID_FIELDS + %w[status priority]).include?(field)

    operator = condition[:filter_operator]
    return presence_clause(field, operator) if %w[is_present is_not_present].include?(operator)

    values = exact_values(field, condition[:values])
    return unless values
    return { terms: { field => values } } if operator == 'equal_to'
    return unless operator == 'not_equal_to'

    { bool: { filter: [{ exists: { field: field } }], must_not: [{ terms: { field => values } }] } }
  end

  def exact_values(field, values)
    return numeric_values(values) if ID_FIELDS.include?(field)

    allowed = field == 'status' ? Conversation.statuses.keys : Conversation.priorities.keys
    return allowed if field == 'status' && values.include?('all')

    values if (values - allowed).empty?
  end

  def numeric_values(values)
    values.map(&:to_i) if values.all? { |value| value.to_s.match?(/\A\d+\z/) }
  end

  def presence_clause(field, operator)
    fields = field == 'assignee_id' ? %w[assignee_id assignee_agent_bot_id] : [field]
    exists = fields.map { |name| { exists: { field: name } } }
    return { bool: { must_not: exists } } if operator == 'is_not_present'

    { bool: { should: exists, minimum_should_match: 1 } }
  end

  def date_clause(condition)
    operator = condition[:filter_operator]
    return unless %w[is_greater_than is_less_than days_before].include?(operator)

    zone = condition.key?(:timezone) ? filter_timezone(condition) : Time.zone
    date = if operator == 'days_before'
             zone.today - Integer(condition[:values].first.to_s, 10).days
           else
             Date.iso8601(condition[:values].first.to_s)
           end
    normalized = condition.merge(timezone: condition[:timezone] || 'Etc/UTC', filter_operator: operator == 'days_before' ? 'is_less_than' : operator)
    boundary = timestamp_filter_boundary(date, normalized)
    { range: { condition[:attribute_key] => { operator == 'is_greater_than' ? :gte : :lt => boundary.iso8601 } } }
  end
end
