require 'rails_helper'

RSpec.describe Migration::RemoveOldCopilotModelSettingsJob, type: :job do
  let(:account) { create(:account) }

  it 'removes the old Copilot choice and keeps the others, so the account can change its models again' do
    account.captain_models = { 'copilot' => 'gpt-6-luna', 'copilot_workflows' => 'gpt-5.2', 'editor' => 'gpt-6-luna' }
    account.captain_features = { 'copilot' => true, 'editor' => true }
    # Validation rejects the old Copilot feature, and this setup needs it saved, as it is on accounts that chose it.
    account.save!(validate: false)

    described_class.perform_now

    account.reload
    expect(account.captain_models).to eq('copilot_workflows' => 'gpt-5.2', 'editor' => 'gpt-6-luna')
    expect(account.captain_features).to eq('editor' => true)
    expect(account.update(captain_models: account.captain_models.merge('copilot_workflows' => 'gpt-5.1'))).to be(true)
  end
end
