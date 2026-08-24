require 'rails_helper'

RSpec.describe Captain::ToolCatalog::EvaluationGate do
  let(:evaluation_cases) do
    lambda do |correct_count|
      Array.new(100) do |index|
        {
          'intent_id' => "intent-#{index}",
          'correct' => index < correct_count,
          'provider_schema_rejection' => false,
          'cross_customer_violation' => false,
          'runner_error' => nil
        }
      end
    end
  end
  let(:report) do
    {
      'dataset' => { 'size' => 100 },
      'runs' => {
        'baseline' => {
          'tool_count' => 15,
          'non_available_tools_exposed' => 0,
          'cases' => evaluation_cases.call(100)
        },
        'candidate' => {
          'tool_count' => 50,
          'non_available_tools_exposed' => 0,
          'cases' => evaluation_cases.call(95)
        }
      }
    }
  end

  it 'passes at the five percentage point selection boundary with no safety failures' do
    result = described_class.new(report).result

    expect(result['passed']).to be(true)
    expect(result['metrics']).to include(
      'baseline_accuracy' => 1.0,
      'candidate_accuracy' => 0.95,
      'selection_decline_percentage_points' => 5.0
    )
  end

  it 'fails when selection accuracy declines beyond the boundary' do
    report['runs']['candidate']['cases'] = evaluation_cases.call(94)

    result = described_class.new(report).result

    expect(result['passed']).to be(false)
    expect(result.dig('checks', 'selection_decline')).to be(false)
  end

  it 'fails closed for provider schema or cross-customer violations' do
    report['runs']['candidate']['cases'].first.merge!(
      'provider_schema_rejection' => true,
      'cross_customer_violation' => true
    )

    result = described_class.new(report).result

    expect(result['passed']).to be(false)
    expect(result['checks']).to include(
      'provider_schema_rejections' => false,
      'cross_customer_violations' => false
    )
  end
end
