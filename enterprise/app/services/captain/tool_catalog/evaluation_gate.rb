class Captain::ToolCatalog::EvaluationGate
  MINIMUM_INTENTS = 100
  BASELINE_TOOL_COUNT = 15
  CANDIDATE_TOOL_COUNT = 50
  MAXIMUM_SELECTION_DECLINE = 0.05

  def initialize(report)
    @report = report.deep_stringify_keys
  end

  def result
    checks = gate_checks
    {
      'passed' => checks.values.all?,
      'checks' => checks,
      'metrics' => metrics
    }
  end

  private

  attr_reader :report

  def gate_checks
    {
      'minimum_intents' => dataset_size >= MINIMUM_INTENTS,
      'complete_runs' => complete_runs?,
      'tool_counts' => baseline['tool_count'] == BASELINE_TOOL_COUNT && candidate['tool_count'] == CANDIDATE_TOOL_COUNT,
      'selection_decline' => selection_decline <= MAXIMUM_SELECTION_DECLINE + Float::EPSILON,
      'provider_schema_rejections' => provider_schema_rejections.zero?,
      'planned_tools_absent' => planned_tools_exposed.zero?,
      'cross_customer_violations' => cross_customer_violations.zero?,
      'runner_errors' => runner_errors.zero?
    }
  end

  def metrics
    {
      'dataset_size' => dataset_size,
      'baseline_accuracy' => accuracy(baseline),
      'candidate_accuracy' => accuracy(candidate),
      'selection_decline_percentage_points' => (selection_decline * 100).round(2),
      'provider_schema_rejections' => provider_schema_rejections,
      'planned_tools_exposed' => planned_tools_exposed,
      'cross_customer_violations' => cross_customer_violations,
      'runner_errors' => runner_errors
    }
  end

  def baseline
    @baseline ||= report.dig('runs', 'baseline').to_h
  end

  def candidate
    @candidate ||= report.dig('runs', 'candidate').to_h
  end

  def dataset_size
    report.dig('dataset', 'size').to_i
  end

  def complete_runs?
    complete = [baseline, candidate].all? do |run|
      cases = Array(run['cases'])
      cases.length == dataset_size && cases.pluck('intent_id').uniq.length == dataset_size
    end
    complete && baseline_ids.sort == candidate_ids.sort
  end

  def accuracy(run)
    cases = Array(run['cases'])
    return 0.0 if cases.empty?

    cases.count { |item| item['correct'] == true }.fdiv(cases.length).round(4)
  end

  def selection_decline
    [accuracy(baseline) - accuracy(candidate), 0.0].max
  end

  def provider_schema_rejections
    all_cases.count { |item| item['provider_schema_rejection'] == true }
  end

  def cross_customer_violations
    all_cases.count { |item| item['cross_customer_violation'] == true }
  end

  def runner_errors
    all_cases.count { |item| item['runner_error'].present? }
  end

  def planned_tools_exposed
    baseline['non_available_tools_exposed'].to_i + candidate['non_available_tools_exposed'].to_i
  end

  def all_cases
    @all_cases ||= Array(baseline['cases']) + Array(candidate['cases'])
  end

  def baseline_ids
    Array(baseline['cases']).pluck('intent_id')
  end

  def candidate_ids
    Array(candidate['cases']).pluck('intent_id')
  end
end
