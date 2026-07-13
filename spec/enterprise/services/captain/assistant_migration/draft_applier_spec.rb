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
      'response_guideline' => 'For account-specific billing issues, collect the invoice number and summarize the issue before escalating.',
      'tool_ids' => []
    }
  end
  let(:faq_document_candidate) do
    {
      'question' => 'When is support available?',
      'answer' => 'Support is available Monday to Friday.'
    }
  end
  let(:draft) do
    {
      business_product_context: ['Support assistant for Test Product.'],
      response_guidelines: ['Be concise.'],
      guardrails: ['Do not guess.'],
      conversation_messages: {},
      scenario_candidates: [scenario_candidate],
      faq_document_candidates: [faq_document_candidate],
      needs_review: ['Pricing details are missing because factual details are absent from the source instructions.']
    }
  end

  describe '#perform' do
    it 'reports staged scenario candidates in dry run without writing to the assistant' do
      result = described_class.new(assistant: assistant, draft: draft, dry_run: true).perform

      expect(result.dig(:changes, :config, :to, 'assistant_migration', 'scenario_candidates')).to eq([scenario_candidate])
      expect(result.dig(:changes, :response_guidelines, :to)).to include(
        'For account-specific billing issues, collect the invoice number and summarize the issue before escalating.'
      )
      expect(assistant.reload.config).not_to have_key('assistant_migration')
      expect(assistant.scenarios.count).to eq(0)
    end

    it 'stores scenario candidates in assistant config and flattens them into response guidelines' do
      described_class.new(assistant: assistant, draft: draft, dry_run: false).perform

      assistant.reload
      expect(assistant.config.dig('assistant_migration', 'scenario_candidates')).to eq([scenario_candidate])
      expect(assistant.config.dig('assistant_migration', 'faq_document_candidates')).to contain_exactly(faq_document_candidate)
      expect(assistant.config.dig('assistant_migration', 'needs_review')).to contain_exactly(
        'Pricing details are missing because factual details are absent from the source instructions.'
      )
      expect(assistant.response_guidelines).to include(
        'For account-specific billing issues, collect the invoice number and summarize the issue before escalating.'
      )
      expect(assistant.response_guidelines).not_to include(faq_document_candidate['answer'])
      expect(assistant.scenarios.count).to eq(0)
    end

    it 'rejects stale drafts whose FAQ candidates use the old string format' do
      stale_draft = draft.merge(faq_document_candidates: ['Support is available Monday to Friday.'])

      expect do
        described_class.new(assistant: assistant, draft: stale_draft, dry_run: false).perform
      end.to raise_error(ArgumentError, 'FAQ document candidates must be question and answer objects')

      expect(assistant.reload.config).not_to have_key('assistant_migration')
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

    it 'rejects an oversized assistant description from a stale draft' do
      long_context = 'This assistant supports a very broad product surface with many long details. ' * 10
      original_description = assistant.description

      expect do
        described_class.new(
          assistant: assistant,
          draft: draft.merge(business_product_context: [long_context]),
          dry_run: false
        ).perform
      end.to raise_error(ArgumentError, 'Assistant description exceeds 500 characters')

      expect(assistant.reload.description).to eq(original_description)
    end
  end
end
