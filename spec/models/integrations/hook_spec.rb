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

  describe 'process_event' do
    let(:account) { create(:account) }
    let(:params) { { event: 'rephrase', payload: { test: 'test' } } }

    it 'returns no processor found for hooks with out processor defined' do
      hook = create(:integrations_hook, account: account)
      expect(hook.process_event(params)).to eq({ :error => 'No processor found' })
    end

    it 'returns results from procesor for openai hook' do
      hook = create(:integrations_hook, :openai, account: account)

      openai_double = double
      allow(Integrations::Openai::ProcessorService).to receive(:new).and_return(openai_double)
      allow(openai_double).to receive(:perform).and_return('test')
      expect(hook.process_event(params)).to eq('test')
      expect(Integrations::Openai::ProcessorService).to have_received(:new).with(event: params, hook: hook)
      expect(openai_double).to have_received(:perform)
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
      expect(described_class.account_hooks).to include(account_hook)
      expect(described_class.account_hooks).not_to include(inbox_hook)
    end

    it 'returns inbox hooks' do
      expect(described_class.inbox_hooks).to include(inbox_hook)
      expect(described_class.inbox_hooks).not_to include(account_hook)
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
end
