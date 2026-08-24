require 'rails_helper'

RSpec.describe Captain::ToolCatalog::EvaluationRunner do
  subject(:runner) { described_class.new(model: 'evaluation-model') }

  it 'validates the versioned 105-intent, 15-tool and 50-tool configurations without model calls' do
    expect(runner.validation_summary).to include(
      'dataset_size' => 105,
      'baseline_tool_count' => 15,
      'candidate_tool_count' => 50,
      'non_available_tools_exposed' => 0
    )
    expect(runner.validation_summary.fetch('dataset_digest')).to match(/\Asha256:[a-f0-9]{64}\z/)
  end
end
