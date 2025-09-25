require 'rails_helper'

RSpec.describe Inboxes::FetchImapEmailInboxesJob do
  let(:account) { create(:account) }
  let(:suspended_account) { create(:account, status: 'suspended') }
  let(:premium_account) { create(:account, custom_attributes: { plan_name: 'Startups' }) }

  let(:imap_email_channel) do
    create(:channel_email, imap_enabled: true, account: account)
  end

  let(:imap_email_channel_suspended) do
    create(:channel_email, imap_enabled: true, account: suspended_account)
  end

  let(:disabled_imap_channel) do
    create(:channel_email, imap_enabled: false, account: account)
  end

  let(:reauth_required_channel) do
    create(:channel_email, imap_enabled: true, account: account)
  end

  let(:premium_imap_channel) do
    create(:channel_email, imap_enabled: true, account: premium_account)
  end

  before do
    reauth_required_channel.prompt_reauthorization!
    premium_account.custom_attributes['plan_name'] = 'Startups'
  end

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  context 'when called' do
    it 'fetches emails only for active accounts with imap enabled' do
      # Should call perform_later only once for the active, imap-enabled inbox
      expect(Inboxes::FetchImapEmailsJob).to receive(:perform_later).with(imap_email_channel).once

      # Should not call for suspended account or disabled IMAP channels
      expect(Inboxes::FetchImapEmailsJob).not_to receive(:perform_later).with(imap_email_channel_suspended)
      expect(Inboxes::FetchImapEmailsJob).not_to receive(:perform_later).with(disabled_imap_channel)

      described_class.perform_now
    end

    it 'skips suspended accounts' do
      expect(Inboxes::FetchImapEmailsJob).not_to receive(:perform_later).with(imap_email_channel_suspended)

      described_class.perform_now
    end

    it 'skips disabled imap channels' do
      expect(Inboxes::FetchImapEmailsJob).not_to receive(:perform_later).with(disabled_imap_channel)

      described_class.perform_now
    end

    it 'skips channels requiring reauthorization' do
      expect(Inboxes::FetchImapEmailsJob).not_to receive(:perform_later).with(reauth_required_channel)

      described_class.perform_now
    end
  end
end
