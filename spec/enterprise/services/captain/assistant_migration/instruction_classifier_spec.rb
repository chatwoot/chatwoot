require 'rails_helper'

RSpec.describe Captain::AssistantMigration::InstructionClassifier do
  describe Captain::AssistantMigration::InstructionClassifierSchema do
    it 'does not request classification notes' do
      expect(described_class.as_json.to_s).not_to include('classification_notes')
    end
  end

  describe 'classifier prompt' do
    it 'keeps the model focused on active behavior and pending FAQ candidates' do
      prompt = Captain::PromptRenderer.render('instruction_classifier')

      expect(prompt).to include(
        'The original custom instructions remain stored unchanged',
        'A FAQ cannot implicitly preserve an action',
        'Scenario candidates remain pending metadata',
        'FAQ candidates are pending review metadata',
        'an error code that requires immediate',
        'actively require specialist-name verification',
        'Mandatory prohibitions are not FAQ-only',
        'never promise refunds after 30 days',
        'never recommend cooking the product',
        'Treat explicit policy boundaries',
        'outside the stated condition, window, or exception',
        'every mandatory action and prohibition remains active'
      )
    end
  end

  describe Captain::AssistantMigration::InstructionAuditorSchema do
    it 'only permits additions that fit in the generated draft' do
      schema = described_class.for(
        response_guidelines: 0,
        guardrails: 2,
        scenario_candidates: 1,
        faq_document_candidates: 3
      ).new.to_json_schema[:schema]

      expect(schema[:properties]).not_to have_key(:response_guidelines)
      expect(schema.dig(:properties, :guardrails, :maxItems)).to eq(2)
      expect(schema.dig(:properties, :scenario_candidates, :maxItems)).to eq(1)
      expect(schema.dig(:properties, :faq_document_candidates, :maxItems)).to eq(3)
      expect(schema[:properties]).not_to have_key(:needs_review)
    end
  end

  describe 'auditor prompt' do
    it 'adds missing coverage without replacing the generated draft' do
      prompt = Captain::PromptRenderer.render('instruction_auditor')

      expect(prompt).to include(
        'This is a monotonic coverage audit',
        'Never repeat, rewrite, replace, or delete content',
        'If mandatory behavior appears only there, add the missing active guideline or guardrail',
        'available_additions gives the exact remaining capacity',
        'No mandatory action or prohibition remains FAQ-only'
      )
    end
  end
end
