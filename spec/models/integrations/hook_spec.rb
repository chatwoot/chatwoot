require 'rails_helper'
require Rails.root.join 'spec/models/concerns/reauthorizable_shared.rb'

RSpec.describe Integrations::Hook do
  it_behaves_like 'reauthorizable'

  context 'with validations' do
    it { is_expected.to validate_presence_of(:app_id) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'when trying to create multiple hooks for an app' do
    let(:account) { create(:account) }

    context 'when app allows multiple hooks' do
      it 'allows to create succesfully' do
        create(:integrations_hook, account: account, app_id: 'webhook')
        expect(build(:integrations_hook, account: account, app_id: 'webhook').valid?).to be true
      end
    end

    context 'when app doesnot allow multiple hooks' do
      it 'throws invalid error' do
        create(:integrations_hook, account: account, app_id: 'slack')
        expect(build(:integrations_hook, account: account, app_id: 'slack').valid?).to be false
      end
    end
  end

  describe 'scopes' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let!(:account_hook) { create(:integrations_hook, account: account, app_id: 'webhook') }
    let!(:inbox_hook) do
      create(:integrations_hook,
             account: account,
             app_id: 'dialogflow',
             inbox: inbox,
             settings: {
               project_id: 'test-project',
               credentials: { type: 'service_account' }
             })
    end

    it 'returns account hooks' do
      expect(described_class.account_hooks.pluck(:id)).to include(account_hook.id)
      expect(described_class.account_hooks.pluck(:id)).not_to include(inbox_hook.id)
    end

    it 'returns inbox hooks' do
      expect(described_class.inbox_hooks.pluck(:id)).to include(inbox_hook.id)
      expect(described_class.inbox_hooks.pluck(:id)).not_to include(account_hook.id)
    end
  end

  describe '#crm_integration?' do
    let(:account) { create(:account) }

    before do
      account.enable_features('crm_integration')
    end

    it 'returns true for leadsquared integration' do
      hook = create(:integrations_hook,
                    account: account,
                    app_id: 'leadsquared',
                    settings: {
                      access_key: 'test',
                      secret_key: 'test',
                      endpoint_url: 'https://api.leadsquared.com'
                    })
      expect(hook.send(:crm_integration?)).to be true
    end

    it 'returns false for non-crm integrations' do
      hook = create(:integrations_hook, account: account, app_id: 'slack')
      expect(hook.send(:crm_integration?)).to be false
    end
  end

  describe '#trigger_setup_if_crm' do
    let(:account) { create(:account) }

    before do
      account.enable_features('crm_integration')
      allow(Crm::SetupJob).to receive(:perform_later)
    end

    context 'when integration is a CRM' do
      it 'enqueues setup job' do
        create(:integrations_hook,
               account: account,
               app_id: 'leadsquared',
               settings: {
                 access_key: 'test',
                 secret_key: 'test',
                 endpoint_url: 'https://api.leadsquared.com'
               })
        expect(Crm::SetupJob).to have_received(:perform_later)
      end
    end

    context 'when integration is not a CRM' do
      it 'does not enqueue setup job' do
        create(:integrations_hook, account: account, app_id: 'slack')
        expect(Crm::SetupJob).not_to have_received(:perform_later)
      end
    end
  end

  describe 'openai api key validation' do
    let(:account) { create(:account) }

    it 'prevents saving an openai hook with an invalid key' do
      allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(false)

      hook = build(:integrations_hook, :openai, account: account, settings: { 'api_key' => 'sk-bad' })

      expect(hook).not_to be_valid
      expect(hook.errors[:base]).to include(I18n.t('errors.openai.invalid_api_key'))
    end

    it 'prevents saving an openai hook with a blank key' do
      hook = build(:integrations_hook, :openai, account: account, settings: { 'api_key' => '' })

      expect(hook).not_to be_valid
    end

    it 'allows saving an openai hook with a valid key' do
      allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(true)

      hook = build(:integrations_hook, :openai, account: account, settings: { 'api_key' => 'sk-good' })

      expect(hook).to be_valid
    end

    it 'skips validation when an enabled openai hook is saved without changing the api key' do
      allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(true)
      hook = create(:integrations_hook, :openai, account: account, settings: { 'api_key' => 'sk-good', 'label_suggestion' => false })

      allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(false)
      hook.settings['label_suggestion'] = true

      expect(hook.save).to be true
    end

    it 'validates when a disabled openai hook is re-enabled' do
      allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(true)
      hook = create(:integrations_hook, :openai, account: account, settings: { 'api_key' => 'sk-bad' })
      hook.update!(status: :disabled)

      allow(Integrations::Openai::KeyValidator).to receive(:valid?).with('sk-bad').and_return(false)

      expect(hook.update(status: :enabled)).to be false
      expect(hook.errors[:base]).to include(I18n.t('errors.openai.invalid_api_key'))
    end

    it 'skips validation for disabled hooks' do
      allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(true)
      hook = create(:integrations_hook, :openai, account: account, settings: { 'api_key' => 'sk-good' })

      # Even with validator returning false, disable succeeds because disabled hooks skip validation
      allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(false)
      hook.disable
      expect(hook.reload).to be_disabled
    end

    it 'does not validate keys for non-openai hooks' do
      allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(false)

      hook = build(:integrations_hook, account: account, app_id: 'slack')

      expect(hook).to be_valid
    end
  end
end
