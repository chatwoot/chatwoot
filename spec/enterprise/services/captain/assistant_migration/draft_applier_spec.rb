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
      'answer' => "Support is available Monday to Friday.\n\nUrgent requests are handled by the on-call team."
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
      expect(result.dig(:changes, :faq_responses, :create)).to contain_exactly(
        faq_document_candidate.merge('status' => 'approved')
      )
      expect(assistant.reload.config).not_to have_key('assistant_migration')
      expect(assistant.responses.count).to eq(0)
      expect(assistant.scenarios.count).to eq(0)
    end

    it 'stores scenario and FAQ candidates and creates approved FAQ responses' do
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
      expect(assistant.responses).to contain_exactly(
        have_attributes(
          question: faq_document_candidate['question'],
          answer: faq_document_candidate['answer'],
          status: 'approved'
        )
      )
      expect(assistant.scenarios.count).to eq(0)

      expect do
        described_class.new(assistant: assistant, draft: draft, dry_run: false).perform
      end.not_to(change { assistant.responses.count })
    end

    it 'leaves pending FAQ responses untouched' do
      pending_response = assistant.responses.create!(
        question: faq_document_candidate['question'],
        answer: faq_document_candidate['answer'],
        status: :pending
      )

      described_class.new(assistant: assistant, draft: draft, dry_run: false).perform

      expect(pending_response.reload).to be_pending
      expect(assistant.responses.approved).to contain_exactly(
        have_attributes(
          question: faq_document_candidate['question'],
          answer: faq_document_candidate['answer']
        )
      )
    end

    it 'rejects conflicting FAQ answers within the same draft' do
      conflicting_draft = draft.merge(
        faq_document_candidates: [
          faq_document_candidate,
          {
            'question' => "When is support\navailable?",
            'answer' => 'Support is available every day.'
          }
        ]
      )

      expect do
        described_class.new(assistant: assistant, draft: conflicting_draft, dry_run: true).perform
      end.to raise_error(ArgumentError, 'FAQ candidate conflicts with an existing FAQ: When is support available?')

      expect(assistant.responses.count).to eq(0)
      expect(assistant.config).not_to have_key('assistant_migration')
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
      expect(assistant.response_guidelines).to include(
        'Use plain language.',
        'Be concise.',
        'For account-specific billing issues, collect the invoice number and summarize the issue before escalating.'
      )
      expect(assistant.guardrails).to contain_exactly('Do not disclose internal notes.', 'Do not guess.')
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
