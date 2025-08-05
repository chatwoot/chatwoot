require 'rails_helper'

RSpec.describe Inboxes::FetchImapEmailInboxesJob do
  context 'when chatwoot_cloud is enabled' do
    let(:account) { create(:account) }
    let(:premium_account) { create(:account, custom_attributes: { plan_name: 'Startups' }) }
    let(:imap_email_channel) { create(:channel_email, imap_enabled: true, account: account) }
    let(:premium_imap_channel) { create(:channel_email, imap_enabled: true, account: premium_account) }

    before do
      premium_account.custom_attributes['plan_name'] = 'Startups'
      InstallationConfig.where(name: 'DEPLOYMENT_ENV').first_or_create!(value: 'cloud')
      InstallationConfig.where(name: 'CHATWOOT_CLOUD_PLANS').first_or_create!(value: [{ 'name' => 'Hacker' }])
    end

    it 'skips inboxes with default plan' do
      expect(Inboxes::FetchImapEmailsJob).not_to receive(:perform_later).with(imap_email_channel)
      described_class.perform_now
    end

    it 'processes inboxes with premium plan' do
      expect(Inboxes::FetchImapEmailsJob).to receive(:perform_later).with(premium_imap_channel)
      described_class.perform_now
    end
  end
end
