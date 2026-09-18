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

  it 'enqueues only the first job and prevents a second campaign trigger' do
    expect { campaign.trigger! }.to have_enqueued_job(described_class).with(campaign).exactly(:once)
    expect(campaign.reload).to be_processing
    expect { campaign.trigger! }.not_to have_enqueued_job(described_class)
  end

  it 'completes an empty campaign' do
    campaign.processing!
    described_class.perform_now(campaign)
    expect(campaign.reload).to be_completed
  end

  it 'sends bounded batches using the last contact ID and completes after the last batch' do
    contacts = create_list(:contact, 3, account: account)
    contacts.each { |contact| contact.update_labels([label.title]) }
    campaign.processing!
    service = Whatsapp::OneoffCampaignService.new(campaign: campaign)
    allow(Whatsapp::OneoffCampaignService).to receive(:new).and_return(service)
    expect(service).to receive(:process_contacts).with(contacts.first(2))

    expect { described_class.perform_now(campaign) }.to have_enqueued_job(described_class).with(campaign, contacts.second.id)
    expect(campaign.reload).to be_processing

    expect(service).to receive(:process_contacts).with([contacts.last])
    described_class.perform_now(campaign, contacts.second.id)
    expect(campaign.reload).to be_completed
  end

  it 'uses current label membership for subsequent batches' do
    contacts = create_list(:contact, 3, account: account)
    contacts.each { |contact| contact.update_labels([label.title]) }
    contacts.last.update_labels([])
    campaign.processing!
    service = Whatsapp::OneoffCampaignService.new(campaign: campaign)
    allow(Whatsapp::OneoffCampaignService).to receive(:new).and_return(service)
    expect(service).to receive(:process_contacts).with([])

    described_class.perform_now(campaign, contacts.second.id)
    expect(campaign.reload).to be_completed
  end

  it 'leaves the campaign processing when sending raises' do
    campaign.processing!
    allow(Whatsapp::OneoffCampaignService).to receive(:new).and_return(sender)
    allow(sender).to receive(:perform_batch).and_raise(StandardError, 'interrupted')

    expect { described_class.perform_now(campaign) }.to raise_error(StandardError, 'interrupted')
    expect(campaign.reload).to be_processing
  end

  it 'ignores jobs for completed campaigns' do
    campaign.completed!
    expect(Whatsapp::OneoffCampaignService).not_to receive(:new)
    described_class.perform_now(campaign)
  end

  it 'finishes an exactly full batch through an empty continuation' do
    contacts = create_list(:contact, 2, account: account)
    contacts.each { |contact| contact.update_labels([label.title]) }
    campaign.processing!
    service = Whatsapp::OneoffCampaignService.new(campaign: campaign)
    allow(Whatsapp::OneoffCampaignService).to receive(:new).and_return(service)
    expect(service).to receive(:process_contacts).with(contacts)

    expect { described_class.perform_now(campaign) }.to have_enqueued_job(described_class).with(campaign, contacts.last.id)
    expect(campaign.reload).to be_processing
    expect(service).to receive(:process_contacts).with([])

    described_class.perform_now(campaign, contacts.last.id)
    expect(campaign.reload).to be_completed
  end

  it 'lets an already started campaign finish after its feature is disabled' do
    campaign.trigger!
    account.disable_features!(:whatsapp_campaign)
    campaign.reload

    described_class.perform_now(campaign)

    expect(campaign.reload).to be_completed
    expect { Whatsapp::OneoffCampaignService.new(campaign: create(:campaign, account: account, inbox: channel.inbox)).perform }
      .to raise_error('WhatsApp campaigns feature not enabled')
  end
end
