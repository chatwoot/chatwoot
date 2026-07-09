require 'rails_helper'

RSpec.describe Captain::AssistantMigration::DraftApplier do
  let(:account) { create(:account) }
  let(:assistant) do
    create(
      :captain_assistant,
      account: account,
      config: { 'product_name' => 'Test Product', 'instructions' => 'Legacy V1 custom instructions.' },
      response_guidelines: [],
      guardrails: []
    )
  end
  let(:scenario_candidate) do
    {
      'title' => 'Billing Investigation',
      'description' => 'Use when a customer reports an account-specific billing issue.',
      'instruction' => 'Collect the invoice number and summarize the issue before escalating.',
      'tool_ids' => []
    }
  end
  let(:draft) do
    {
      business_product_context: ['Support assistant for Test Product.'],
      response_guidelines: ['Be concise.'],
      guardrails: ['Do not guess.'],
      conversation_messages: {},
      scenario_candidates: [scenario_candidate],
      faq_document_candidates: ['Support hours are Monday to Friday.'],
      needs_review: ['Pricing details are missing because factual details are absent from the source instructions.']
    }
  end

  describe '#perform' do
    it 'reports staged scenario candidates in dry run without writing to the assistant' do
      result = described_class.new(assistant: assistant, draft: draft, dry_run: true).perform

      expect(result.dig(:changes, :config, :to, 'assistant_migration', 'scenario_candidates')).to eq([scenario_candidate])
      expect(result.dig(:changes, :response_guidelines, :to)).to include(
        "Scenario candidate: Billing Investigation\nUse when: Use when a customer reports an account-specific billing issue.\n" \
        'Instructions: Collect the invoice number and summarize the issue before escalating.'
      )
      expect(assistant.reload.config).not_to have_key('assistant_migration')
      expect(assistant.scenarios.count).to eq(0)
    end

    it 'stores scenario candidates in assistant config and flattens them into response guidelines' do
      described_class.new(assistant: assistant, draft: draft, dry_run: false).perform

      assistant.reload
      expect(assistant.config.dig('assistant_migration', 'scenario_candidates')).to eq([scenario_candidate])
      expect(assistant.config.dig('assistant_migration', 'faq_document_candidates')).to contain_exactly('Support hours are Monday to Friday.')
      expect(assistant.config.dig('assistant_migration', 'needs_review')).to contain_exactly(
        'Pricing details are missing because factual details are absent from the source instructions.'
      )
      expect(assistant.response_guidelines).to include(
        "Scenario candidate: Billing Investigation\nUse when: Use when a customer reports an account-specific billing issue.\n" \
        'Instructions: Collect the invoice number and summarize the issue before escalating.'
      )
      expect(assistant.scenarios.count).to eq(0)
    end

    it 'preserves original values in migration config before applying classifier output' do
      assistant.update!(
        description: 'Existing assistant description.',
        response_guidelines: ['Use plain language.'],
        guardrails: ['Do not disclose internal notes.']
      )

      described_class.new(assistant: assistant, draft: draft, dry_run: false).perform

      assistant.reload
      expect(assistant.description).to eq('Support assistant for Test Product.')
      expect(assistant.response_guidelines).to include('Be concise.')
      expect(assistant.guardrails).to eq(['Do not guess.'])
      expect(assistant.config.dig('assistant_migration', 'original_values')).to include(
        'name' => assistant.name,
        'description' => 'Existing assistant description.',
        'config' => { 'product_name' => 'Test Product', 'instructions' => 'Legacy V1 custom instructions.' },
        'response_guidelines' => ['Use plain language.'],
        'guardrails' => ['Do not disclose internal notes.']
      )
    end
  end
end
