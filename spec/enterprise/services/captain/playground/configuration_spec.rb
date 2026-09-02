require 'rails_helper'

RSpec.describe Captain::Playground::Configuration do
  let(:account) { create(:account) }
  let(:assistant) do
    create(
      :captain_assistant,
      account: account,
      response_guidelines: ['Saved guideline'],
      guardrails: ['Saved guardrail']
    )
  end
  let!(:enabled_scenario) { create(:captain_scenario, assistant: assistant, account: account, enabled: true) }
  let!(:disabled_scenario) { create(:captain_scenario, assistant: assistant, account: account, enabled: false) }

  describe '#initialize' do
    it 'uses the enabled scenarios and saved rules by default' do
      configuration = described_class.new(assistant: assistant, params: {})

      expect(configuration.scenarios).to eq([enabled_scenario])
      expect(configuration.response_guidelines).to eq(['Saved guideline'])
      expect(configuration.guardrails).to eq(['Saved guardrail'])
    end

    it 'includes selected disabled scenarios and replaces the saved rules' do
      configuration = described_class.new(
        assistant: assistant,
        params: {
          scenario_ids: [disabled_scenario.id],
          response_guidelines: ['Runtime guideline'],
          guardrails: []
        }
      )

      expect(configuration.scenarios).to eq([disabled_scenario])
      expect(configuration.response_guidelines).to eq(['Runtime guideline'])
      expect(configuration.guardrails).to be_empty
    end

    it 'builds validated temporary scenarios with unique handoff names without saving them' do
      params = {
        scenario_ids: [],
        temporary_scenarios: [
          {
            client_id: 'first', title: 'Refund request', description: 'Handle refunds',
            instruction: 'Use [Update Priority](tool://update_priority)'
          },
          {
            client_id: 'second', title: 'Refund request', description: 'Handle another refund',
            instruction: 'Reply with the refund policy'
          }
        ]
      }

      expect do
        configuration = described_class.new(assistant: assistant, params: params)
        first, second = configuration.scenarios

        expect(first).to be_valid
        expect(first.tools).to eq(['update_priority'])
        expect(configuration.temporary?(first)).to be true
        expect(configuration.agent_name_for(first)).not_to eq(configuration.agent_name_for(second))
      end.not_to change(Captain::Scenario, :count)
    end

    it 'keeps a temporary scenario handoff name stable across edits and reordering' do
      original = described_class.new(
        assistant: assistant,
        params: {
          scenario_ids: [],
          temporary_scenarios: [
            { client_id: 'stable', title: 'Refund request', description: 'Handle refunds', instruction: 'Follow policy' }
          ]
        }
      )
      reordered = described_class.new(
        assistant: assistant,
        params: {
          scenario_ids: [],
          temporary_scenarios: [
            { client_id: 'other', title: 'Other', description: 'Other request', instruction: 'Reply normally' },
            { client_id: 'stable', title: 'Returns', description: 'Handle returns', instruction: 'Follow the returns policy' }
          ]
        }
      )

      stable_scenario = reordered.scenarios.find { |scenario| scenario.title == 'Returns' }
      expect(reordered.agent_name_for(stable_scenario)).to eq(original.agent_name_for(original.scenarios.first))
    end

    it 'rejects duplicate temporary scenario client IDs' do
      params = {
        temporary_scenarios: [
          { client_id: 'duplicate', title: 'First', description: 'First request', instruction: 'Reply first' },
          { client_id: 'duplicate', title: 'Second', description: 'Second request', instruction: 'Reply second' }
        ]
      }

      expect { described_class.new(assistant: assistant, params: params) }.to raise_error(described_class::Invalid) do |error|
        expect(error.errors['temporary_scenarios']).to eq(['must contain unique client IDs'])
      end
    end

    it 'rejects scenarios that do not belong to the assistant' do
      other_assistant = create(:captain_assistant, account: account)
      other_scenario = create(:captain_scenario, assistant: other_assistant, account: account)

      expect do
        described_class.new(assistant: assistant, params: { scenario_ids: [other_scenario.id] })
      end.to raise_error(described_class::Invalid) { |error| expect(error.errors['scenario_ids']).to include(/unavailable scenarios/) }
    end

    it 'rejects invalid temporary scenario tool references' do
      params = {
        temporary_scenarios: [
          {
            client_id: 'invalid', title: 'Invalid tool', description: 'Invalid tool',
            instruction: 'Use [Unknown](tool://not_configured)'
          }
        ]
      }

      error_key = 'temporary_scenarios.0.instruction'
      expect do
        described_class.new(assistant: assistant, params: params)
      end.to raise_error(described_class::Invalid) { |error| expect(error.errors[error_key]).to include(/contains invalid tools/) }
    end

    it 'returns structured errors for malformed configuration objects' do
      build_configuration = ->(params) { described_class.new(assistant: assistant, params: params) }

      expect { build_configuration.call('invalid') }.to raise_error(described_class::Invalid) do |error|
        expect(error.errors['playground_config']).to eq(['must be an object'])
      end

      expect { build_configuration.call(temporary_scenarios: ['invalid']) }.to raise_error(described_class::Invalid) do |error|
        expect(error.errors['temporary_scenarios.0']).to eq(['must be an object'])
      end
    end

    it 'rejects fractional scenario IDs instead of coercing them' do
      expect do
        described_class.new(assistant: assistant, params: { scenario_ids: [enabled_scenario.id.to_f] })
      end.to raise_error(described_class::Invalid)
    end

    it 'rejects temporary knowledge over the limit' do
      expected_errors = ['is limited to 10000 characters']
      expect do
        described_class.new(
          assistant: assistant,
          params: { knowledge_text: 'a' * 10_001 }
        )
      end.to raise_error(described_class::Invalid) { |error| expect(error.errors['knowledge_text']).to eq(expected_errors) }
    end

    it 'does not modify Captain configuration rows' do
      counts = {
        assistants: Captain::Assistant.count,
        scenarios: Captain::Scenario.count,
        guidelines: assistant.response_guidelines,
        guardrails: assistant.guardrails
      }

      described_class.new(
        assistant: assistant,
        params: {
          scenario_ids: [disabled_scenario.id],
          temporary_scenarios: [
            { client_id: 'local', title: 'Local', description: 'Local only', instruction: 'Reply locally' }
          ],
          response_guidelines: ['Temporary guideline'],
          guardrails: ['Temporary guardrail']
        }
      )

      expect(Captain::Assistant.count).to eq(counts[:assistants])
      expect(Captain::Scenario.count).to eq(counts[:scenarios])
      expect(assistant.reload.response_guidelines).to eq(counts[:guidelines])
      expect(assistant.guardrails).to eq(counts[:guardrails])
    end
  end

  describe '#prompt_context_for' do
    it 'attaches runtime rules, selected scenarios, and delimited knowledge to assistant and scenario prompts' do
      configuration = described_class.new(
        assistant: assistant,
        params: {
          scenario_ids: [disabled_scenario.id],
          response_guidelines: ['Runtime guideline'],
          guardrails: ['Runtime guardrail'],
          knowledge_text: 'Refunds take five days.'
        }
      )

      assistant_prompt = assistant.agent_instructions(nil, runtime_configuration: configuration)
      selected_scenario = configuration.scenarios.first
      scenario_prompt = selected_scenario.agent_instructions(nil, runtime_configuration: configuration)

      expect(assistant_prompt).to include('Runtime guideline', 'Runtime guardrail', 'Refunds take five days.')
      expect(assistant_prompt).to include(configuration.agent_name_for(selected_scenario))
      expect(assistant_prompt).not_to include('Saved guideline', 'Saved guardrail')
      expect(scenario_prompt).to include('Runtime guideline', 'Runtime guardrail', 'Refunds take five days.')
      expect(scenario_prompt).to include('BEGIN PLAYGROUND REFERENCE', 'END PLAYGROUND REFERENCE')
    end
  end
end
