require 'rails_helper'

RSpec.describe Migration::ValidateOpenaiHooksJob do
  let(:integrations_mailer) { instance_double(AdministratorNotifications::IntegrationsNotificationMailer) }
  let(:mailer_response) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(true)
    allow(AdministratorNotifications::IntegrationsNotificationMailer).to receive(:with).and_return(integrations_mailer)
    allow(integrations_mailer).to receive(:openai_disconnect).and_return(mailer_response)
  end

  def create_openai_hook(account:, api_key: 'sk-good')
    create(:integrations_hook, :openai, account: account, settings: { 'api_key' => api_key })
  end

  it 'destroys invalid hooks, preserves valid ones, sends disconnect email, and reports stats' do
    account_a = create(:account)
    account_b = create(:account)
    valid_hook = create_openai_hook(account: account_a, api_key: 'sk-good')
    invalid_hook = create_openai_hook(account: account_b, api_key: 'sk-bad')
    allow(Integrations::Openai::KeyValidator).to receive(:valid?).with('sk-bad').and_return(false)

    result = described_class.perform_now

    expect(valid_hook.reload).to be_enabled
    expect { invalid_hook.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(AdministratorNotifications::IntegrationsNotificationMailer).to have_received(:with).with(account: account_b)
    expect(result).to eq(checked: 2, destroyed: 1)
  end

  it 'scopes to a specific account when provided' do
    account_a = create(:account)
    account_b = create(:account)
    hook_a = create_openai_hook(account: account_a, api_key: 'sk-bad')
    hook_b = create_openai_hook(account: account_b, api_key: 'sk-bad')
    allow(Integrations::Openai::KeyValidator).to receive(:valid?).with('sk-bad').and_return(false)

    described_class.perform_now(account: account_a)

    expect { hook_a.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(hook_b.reload).to be_enabled
  end

  it 'only checks enabled OpenAI hooks' do
    account = create(:account)
    slack_hook = create(:integrations_hook, account: account, app_id: 'slack')
    disabled_hook = create_openai_hook(account: account)
    disabled_hook.disable

    allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(false)

    described_class.perform_now

    expect(slack_hook.reload).to be_enabled
    expect(disabled_hook.reload).to be_disabled # still disabled, not re-checked
  end
end
