# frozen_string_literal: true

# Evaluates conditional rules and routes to different output handles.
# Supports AND/OR logic across multiple rules.
# Routes to 'flow_true' or 'flow_false' handles.
class Agent::Nodes::ConditionNode < Agent::Nodes::BaseNode
  OPERATORS = {
    'equals' => ->(a, b) { a.to_s == b.to_s },
    'not_equals' => ->(a, b) { a.to_s != b.to_s },
    'contains' => ->(a, b) { a.to_s.include?(b.to_s) },
    'not_contains' => ->(a, b) { a.to_s.exclude?(b.to_s) },
    'starts_with' => ->(a, b) { a.to_s.start_with?(b.to_s) },
    'ends_with' => ->(a, b) { a.to_s.end_with?(b.to_s) },
    'greater_than' => ->(a, b) { a.to_f > b.to_f },
    'less_than' => ->(a, b) { a.to_f < b.to_f },
    'is_empty' => ->(a, _b) { a.blank? },
    'is_not_empty' => ->(a, _b) { a.present? }
  }.freeze

  protected

  def process
    rules = data['rules'] || []
    logic = data['logic'] || 'and'

    result = evaluate_rules(rules, logic)
    handle = result ? 'flow_true' : 'flow_false'
    context.set_variable('condition_result', result)

    { output: { result: result, logic: logic, rules_count: rules.size }, handle: handle }
  end

  private

  def evaluate_rules(rules, logic)
    return true if rules.empty?

    results = rules.map { |rule| evaluate_rule(rule) }

    if logic == 'or'
      results.any?
    else
      results.all?
    end
  end

  def evaluate_rule(rule)
    field_value = context.get_variable(rule['field'])
    operator = OPERATORS[rule['operator']]
    return false unless operator

    operator.call(field_value, rule['value'])
  end
end
