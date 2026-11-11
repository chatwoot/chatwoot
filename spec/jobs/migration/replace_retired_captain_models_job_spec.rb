require 'rails_helper'

RSpec.describe Migration::ReplaceRetiredCaptainModelsJob, type: :job do
  let(:account) { create(:account) }

  def set_installation_config(name, value)
    InstallationConfig.find_or_initialize_by(name: name).update!(value: value)
  end

  it 'moves saved retired models to the default text model and keeps allowed ones' do
    account.captain_models = { 'editor' => 'gpt-5-mini', 'copilot' => 'gpt-4.1', 'assistant' => 'gpt-5.2' }
    # Validation would reject the retired models, and this setup needs them saved.
    account.save!(validate: false)

    described_class.perform_now

    expect(account.reload.captain_models).to eq(
      'editor' => Llm::Config::DEFAULT_MODEL,
      'copilot' => Llm::Config::DEFAULT_MODEL,
      'assistant' => 'gpt-5.2'
    )
  end

  %w[gpt-5 gpt-5-mini-2025-08-07].each do |retired_model|
    it "replaces the retired installation model #{retired_model} on the standard OpenAI endpoint" do
      set_installation_config('CAPTAIN_OPEN_AI_MODEL', retired_model)

      described_class.perform_now

      expect(InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL').value).to eq(Llm::Config::DEFAULT_MODEL)
    end
  end

  it 'keeps the installation model on a custom endpoint' do
    set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://custom.example')
    set_installation_config('CAPTAIN_OPEN_AI_MODEL', 'gpt-5-mini')

    described_class.perform_now

    expect(InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL').value).to eq('gpt-5-mini')
  end
end
