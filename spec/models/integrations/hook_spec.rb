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

  describe 'creating a captain hook' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:settings) { { inbox_ids: inbox.id } }

    it 'raises an error if captain is not enabled' do
      expect { create(:integrations_hook, app_id: 'captain', account: account, settings: settings) }.to raise_error('Captain is not enabled')
    end

    context 'when captain is enabled' do
      before do
        account.enable_features('captain_integration')
        account.save!
        InstallationConfig.where(name: 'CAPTAIN_APP_URL').first_or_create(value: 'https://app.chatwoot.com')
        stub_request(:post, ChatwootHub::CAPTAIN_ACCOUNTS_URL).to_return(body: {
          account_email: 'test@example.com',
          captain_account_id: 1,
          access_token: 'access_token',
          assistant_id: 1
        }.to_json)
      end

      it 'populates the settings with captain settings' do
        hook = create(:integrations_hook, app_id: 'captain', account: account, settings: settings)
        expect(hook.settings['account_email']).to be_present
        expect(hook.settings['assistant_id']).to be_present
        expect(hook.settings['access_token']).to be_present
        expect(hook.settings['assistant_id']).to be_present
      end

      it 'raises an error if the request to captain hub fails' do
        stub_request(:post, ChatwootHub::CAPTAIN_ACCOUNTS_URL).to_return(
          status: 500,
          body: {
            error: 'Failed to get captain settings'
          }.to_json
        )
        expect do
          create(:integrations_hook, app_id: 'captain', account: account, settings: settings)
        end.to raise_error('Failed to get captain settings: {"error":"Failed to get captain settings"}')
      end
    end
  end
end
