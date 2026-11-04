require 'rails_helper'

RSpec.describe Internal::CheckNewVersionsJob do
  subject(:job) { described_class.perform_now }

  let(:reconsile_premium_config_service) { instance_double(Internal::ReconcilePlanConfigService) }

  before do
    allow(Internal::ReconcilePlanConfigService).to receive(:new).and_return(reconsile_premium_config_service)
    allow(reconsile_premium_config_service).to receive(:perform)
    allow(Rails.env).to receive(:production?).and_return(true)
  end

  it 'updates the plan info' do
    data = { 'version' => '1.2.3', 'plan' => 'enterprise', 'plan_quantity' => 1, 'chatwoot_support_website_token' => '123',
             'chatwoot_support_identifier_hash' => '123', 'chatwoot_support_script_url' => '123' }
    allow(ChatwootHub).to receive(:sync_with_hub).and_return(data)
    job
    expect(InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN').value).to eq 'enterprise'
    expect(InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY').value).to eq 1
    expect(InstallationConfig.find_by(name: 'CHATWOOT_SUPPORT_WEBSITE_TOKEN').value).to eq '123'
    expect(InstallationConfig.find_by(name: 'CHATWOOT_SUPPORT_IDENTIFIER_HASH').value).to eq '123'
    expect(InstallationConfig.find_by(name: 'CHATWOOT_SUPPORT_SCRIPT_URL').value).to eq '123'
  end

  it 'calls Internal::ReconcilePlanConfigService' do
    data = { 'version' => '1.2.3' }
    allow(ChatwootHub).to receive(:sync_with_hub).and_return(data)
    job
    expect(reconsile_premium_config_service).to have_received(:perform)
  end

  context 'when hub reports the installation subscription status' do
    let!(:accounts) { create_list(:account, 2) }

    before do
      InstallationConfig.create!(name: 'INSTALLATION_SUBSCRIPTION_STATUS', value: 'active', locked: true)
    end

    it 'stores the new status and notifies every account' do
      allow(ChatwootHub).to receive(:sync_with_hub).and_return({ 'version' => '1.2.3', 'subscription_status' => 'past_due' })

      job

      expect(ChatwootHub.subscription_status).to eq 'past_due'
      expect(ActionCableBroadcastJob).to have_been_enqueued.once
                                                           .with(match_array(accounts.map { |account|
                                                                   "account_#{account.id}"
                                                                 }), 'account.billing_updated', {})
    end

    it 'does not notify accounts when the status is unchanged' do
      allow(ChatwootHub).to receive(:sync_with_hub).and_return({ 'version' => '1.2.3', 'subscription_status' => 'active' })

      job

      expect(ActionCableBroadcastJob).not_to have_been_enqueued
    end

    it 'keeps the last known status when an older hub omits it' do
      allow(ChatwootHub).to receive(:sync_with_hub).and_return({ 'version' => '1.2.3' })

      job

      expect(ChatwootHub.subscription_status).to eq 'active'
    end

    it 'clears the status when hub returns null' do
      allow(ChatwootHub).to receive(:sync_with_hub).and_return({ 'version' => '1.2.3', 'subscription_status' => nil })

      job

      expect(ChatwootHub.subscription_status).to be_nil
    end
  end
end
