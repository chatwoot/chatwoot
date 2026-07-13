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
end
