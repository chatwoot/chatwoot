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
               'project_id' => 'test-project',
               'credentials' => {
                 'type' => 'service_account',
                 'project_id' => 'test-project',
                 'private_key' => 'fake-key',
                 'client_email' => 'test@test-project.iam.gserviceaccount.com'
               }
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

  describe 'Dialogflow credentials validation' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:valid_credentials) do
      {
        'type' => 'service_account',
        'project_id' => 'test-project',
        'private_key' => '-----BEGIN PRIVATE KEY-----
fake
-----END PRIVATE KEY-----',
        'client_email' => 'test@test-project.iam.gserviceaccount.com'
      }
    end

    context 'when credentials are valid' do
      it 'is valid with a complete service account key' do
        hook = build(:integrations_hook,
                     account: account,
                     inbox: inbox,
                     app_id: 'dialogflow',
                     settings: { 'project_id' => 'test-project', 'credentials' => valid_credentials })
        expect(hook).to be_valid
      end
    end

    context 'when project_id is missing' do
      it 'is invalid' do
        hook = build(:integrations_hook,
                     account: account,
                     inbox: inbox,
                     app_id: 'dialogflow',
                     settings: { 'credentials' => valid_credentials })
        expect(hook).not_to be_valid
        expect(hook.errors[:settings].join).to include('project_id is required')
      end
    end

    context 'when credentials are missing' do
      it 'is invalid' do
        hook = build(:integrations_hook,
                     account: account,
                     inbox: inbox,
                     app_id: 'dialogflow',
                     settings: { 'project_id' => 'test-project' })
        expect(hook).not_to be_valid
        expect(hook.errors[:settings].join).to include('credentials are required')
      end
    end

    context 'when credentials hash is missing required fields' do
      it 'is invalid and lists missing fields' do
        hook = build(:integrations_hook,
                     account: account,
                     inbox: inbox,
                     app_id: 'dialogflow',
                     settings: {
                       'project_id' => 'test-project',
                       'credentials' => { 'type' => 'service_account' }
                     })
        expect(hook).not_to be_valid
        expect(hook.errors[:settings].join).to include('missing required fields')
      end
    end

    context 'when credentials type is not service_account' do
      it 'is invalid' do
        bad_credentials = valid_credentials.merge('type' => 'user_account')
        hook = build(:integrations_hook,
                     account: account,
                     inbox: inbox,
                     app_id: 'dialogflow',
                     settings: { 'project_id' => 'test-project', 'credentials' => bad_credentials })
        expect(hook).not_to be_valid
        expect(hook.errors[:settings].join).to include('type must be "service_account"')
      end
    end

    context 'when app is not dialogflow' do
      it 'does not run dialogflow validation' do
        hook = build(:integrations_hook,
                     account: account,
                     app_id: 'slack',
                     settings: { 'test' => 'test' })
        expect(hook).to be_valid
      end
    end
  end
end
