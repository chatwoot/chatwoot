require 'rails_helper'

RSpec.describe Internal::ValidateOpenaiHooksJob do
  before { allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(true) }

  def create_openai_hook(account:, api_key: 'sk-good')
    create(:integrations_hook, :openai, account: account, settings: { 'api_key' => api_key })
  end

  it 'disables invalid hooks, preserves valid ones, and reports stats' do
    account_a = create(:account)
    account_b = create(:account)
    valid_hook = create_openai_hook(account: account_a, api_key: 'sk-good')
    invalid_hook = create_openai_hook(account: account_b, api_key: 'sk-bad')
    allow(Integrations::Openai::KeyValidator).to receive(:valid?).with('sk-bad').and_return(false)

    result = described_class.perform_now

    expect(valid_hook.reload).to be_enabled
    expect(invalid_hook.reload).to be_disabled
    expect(result).to eq(checked: 2, disabled: 1)
  end

  it 'scopes to a specific account when provided' do
    account_a = create(:account)
    account_b = create(:account)
    hook_a = create_openai_hook(account: account_a, api_key: 'sk-bad')
    hook_b = create_openai_hook(account: account_b, api_key: 'sk-bad')
    allow(Integrations::Openai::KeyValidator).to receive(:valid?).with('sk-bad').and_return(false)

    described_class.perform_now(account: account_a)

    expect(hook_a.reload).to be_disabled
    expect(hook_b.reload).to be_enabled
  end

  it 'only checks enabled OpenAI hooks' do
    account = create(:account)
    slack_hook = create(:integrations_hook, account: account, app_id: 'slack')
    disabled_hook = create_openai_hook(account: account)
    disabled_hook.disable

    # Make ALL future validations fail — if the job checks these hooks, they'd be disabled
    allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(false)

    described_class.perform_now

    expect(slack_hook.reload).to be_enabled
    expect(disabled_hook.reload).to be_disabled # still disabled, not re-checked
  end
end
