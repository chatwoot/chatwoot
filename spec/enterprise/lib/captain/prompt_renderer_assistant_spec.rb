require 'rails_helper'

RSpec.describe Captain::PromptRenderer do
  it 'honors explicit handoff requirements without asking for consent again' do
    prompt = described_class.render('assistant')

    expect(prompt).to include(
      'follow it instead of the generic consent-first handoff defaults',
      'A Response Guideline or Guardrail explicitly requires transfer for the matched condition',
      'or a Response Guideline or Guardrail explicitly requires transfer for the matched condition'
    )
  end
end
