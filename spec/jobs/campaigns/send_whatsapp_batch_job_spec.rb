require 'rails_helper'

RSpec.describe Campaigns::SendWhatsappBatchJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:label) { create(:label, account: account) }
  let(:campaign) { create(:campaign, account: account, inbox: channel.inbox, audience: [{ type: 'Label', id: label.id }]) }
  let(:sender) { instance_double(Whatsapp::OneoffCampaignService, perform_batch: nil) }

  before do
    account.enable_features!(:whatsapp_campaign)
    stub_const('Whatsapp::OneoffCampaignService::BATCH_SIZE', 2)
  end

  it 'saves the audience in bounded batches and enqueues only the first' do
    contacts = create_list(:contact, 3, account: account)
    contacts.each { |contact| contact.update_labels([label.title]) }

    expect { campaign.trigger! }.to have_enqueued_job(described_class).exactly(:once)
    expect(campaign.campaign_batches.order(:id).pluck(:contact_ids)).to eq([contacts.first(2).map(&:id), [contacts.last.id]])
    expect(campaign.reload).to be_processing
    expect { campaign.trigger! }.not_to change(CampaignBatch, :count)
  end

  it 'completes an empty campaign without scheduling a send' do
    expect { campaign.trigger! }.not_to have_enqueued_job(described_class)
    expect(campaign.reload).to be_completed
  end

  it 'sends the saved audience and completes only after the last batch' do
    contacts = create_list(:contact, 3, account: account)
    contacts.each { |contact| contact.update_labels([label.title]) }
    campaign.trigger!
    first_batch, last_batch = campaign.campaign_batches.order(:id).to_a
    contacts.each { |contact| contact.update_labels([]) }
    allow(Whatsapp::OneoffCampaignService).to receive(:new).with(campaign: campaign).and_return(sender)

    expect(sender).to receive(:perform_batch).with(first_batch.contact_ids).once
    expect { described_class.perform_now(first_batch) }.to have_enqueued_job(described_class).with(last_batch)
    expect(first_batch.reload.processed_at).to be_present
    expect(campaign.reload).to be_processing

    expect(sender).to receive(:perform_batch).with(last_batch.contact_ids).once
    described_class.perform_now(last_batch)
    expect(campaign.reload).to be_completed
    expect(campaign.completed_at).to be_present
  end

  it 'does not resend a completed batch when its job is repeated' do
    campaign.processing!
    batch = campaign.campaign_batches.create!(contact_ids: [1], processed_at: Time.current)
    campaign.campaign_batches.create!(contact_ids: [2])
    expect(Whatsapp::OneoffCampaignService).not_to receive(:new)

    expect { described_class.perform_now(batch) }.to have_enqueued_job(described_class)
    expect(campaign.reload).to be_processing
  end

  it 'does not mark a batch or campaign completed when processing raises' do
    campaign.processing!
    batch = campaign.campaign_batches.create!(contact_ids: [1])
    allow(Whatsapp::OneoffCampaignService).to receive(:new).and_return(sender)
    allow(sender).to receive(:perform_batch).and_raise(StandardError, 'interrupted')

    expect { described_class.perform_now(batch) }.to raise_error(StandardError, 'interrupted')
    expect(batch.reload.processed_at).to be_nil
    expect(campaign.reload).to be_processing
  end

  it 'ignores jobs for completed campaigns' do
    batch = campaign.campaign_batches.create!(contact_ids: [1])
    campaign.completed!
    expect(Whatsapp::OneoffCampaignService).not_to receive(:new)
    described_class.perform_now(batch)
  end
end
