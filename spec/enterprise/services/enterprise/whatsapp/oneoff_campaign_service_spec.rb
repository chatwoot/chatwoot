require 'rails_helper'

RSpec.describe Enterprise::Whatsapp::OneoffCampaignService do
  let(:account) { create(:account) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:whatsapp_inbox) { whatsapp_channel.inbox }
  let(:label) { create(:label, account: account) }
  let(:template_params) do
    {
      'name' => 'ticket_status_updated',
      'namespace' => '23423423_2342423_324234234_2343224',
      'category' => 'UTILITY',
      'language' => 'en',
      'processed_params' => { 'body' => { 'name' => 'John', 'ticket_id' => '2332' } }
    }
  end
  let(:campaign) do
    create(
      :campaign,
      inbox: whatsapp_inbox,
      account: account,
      audience: [{ type: 'Label', id: label.id }],
      template_params: template_params
    )
  end

  before do
    account.enable_features!(:campaigns)
    allow_any_instance_of(Whatsapp::OneoffCampaignService).to receive(:channel).and_return(whatsapp_channel) # rubocop:disable RSpec/AnyInstance
  end

  it 'records delivery progress across core cursor batches' do
    stub_const('Whatsapp::OneoffCampaignService::BATCH_SIZE', 1)
    contacts = create_list(:contact, 2, :with_phone_number, account: account)
    contacts.each { |contact| contact.update_labels([label.title]) }
    allow(whatsapp_channel).to receive(:send_template).and_return('wamid.first', 'wamid.second')

    campaign.trigger!

    Campaigns::SendWhatsappBatchJob.perform_now(campaign)
    expect(campaign.campaign_recipients.sent.count).to eq(1)
    recipient = campaign.campaign_recipients.sent.first
    expect(recipient.contact_inbox.source_id).to eq(contacts.first.phone_number.delete_prefix('+'))
    expect(recipient.contact_inbox.contact_id).to eq(contacts.first.id)
    expect(campaign.reload).to be_processing

    Campaigns::SendWhatsappBatchJob.perform_now(campaign, contacts.first.id)
    expect(campaign.campaign_recipients.sent.count).to eq(2)
    Campaigns::SendWhatsappBatchJob.perform_now(campaign, contacts.last.id)
    expect(campaign.reload).to be_completed
  end

  [
    ['+5541988887777', '554188887777'],
    ['+554188887777', '5541988887777']
  ].each do |phone_number, source_id|
    it "reuses the existing WhatsApp identity #{source_id} for #{phone_number}" do
      contact = create(:contact, account: account, phone_number: phone_number)
      contact.update_labels([label.title])
      contact_inbox = create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: source_id)
      allow(whatsapp_channel).to receive(:send_template).and_return('wamid.normalized')

      expect do
        Whatsapp::OneoffCampaignService.new(campaign: campaign).perform_batch(0)
      end.not_to change(ContactInbox, :count)

      recipient = campaign.campaign_recipients.find_by!(contact: contact)
      expect(recipient).to be_sent
      expect(recipient.contact_inbox).to eq(contact_inbox)
    end
  end

  it 'does not associate a normalized identity belonging to another contact' do
    contact = create(:contact, account: account, phone_number: '+5541988887777')
    contact.update_labels([label.title])
    other_contact = create(:contact, account: account)
    create(:contact_inbox, contact: other_contact, inbox: whatsapp_inbox, source_id: '554188887777')
    allow(whatsapp_channel).to receive(:send_template).and_return('wamid.original')

    Whatsapp::OneoffCampaignService.new(campaign: campaign).perform_batch(0)

    recipient = campaign.campaign_recipients.find_by!(contact: contact)
    expect(recipient).to be_sent
    expect(recipient.contact_inbox.contact).to eq(contact)
    expect(recipient.contact_inbox.source_id).to eq('5541988887777')
  end

  it 'marks contacts without phone or BSUID as skipped' do
    contact = create(:contact, account: account, phone_number: nil)
    contact.update_labels([label.title])

    expect(whatsapp_channel).not_to receive(:send_template)

    perform_enqueued_jobs do
      Whatsapp::OneoffCampaignService.new(campaign: campaign).perform
    end

    expect(CampaignRecipient.find_by!(campaign: campaign, contact: contact)).to be_skipped
  end

  it 'marks phone-less contacts with multiple WhatsApp identities as skipped' do
    contact = create(:contact, account: account, phone_number: nil)
    contact.update_labels([label.title])
    create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'IN.2081978709342942')
    create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'IN.2081978709342943')

    expect(whatsapp_channel).not_to receive(:send_template)

    perform_enqueued_jobs do
      Whatsapp::OneoffCampaignService.new(campaign: campaign).perform
    end

    expect(CampaignRecipient.find_by!(campaign: campaign, contact: contact)).to be_skipped
  end

  it 'marks blocked BSUID-only authentication-template recipients as skipped' do
    contact = create(:contact, account: account, phone_number: nil)
    contact.update_labels([label.title])
    create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'IN.2081978709342942')
    whatsapp_channel.update!(
      message_templates: [
        {
          'name' => 'ticket_status_updated',
          'language' => 'en',
          'category' => 'AUTHENTICATION'
        }
      ]
    )

    expect(whatsapp_channel).not_to receive(:send_template)

    perform_enqueued_jobs do
      Whatsapp::OneoffCampaignService.new(campaign: campaign).perform
    end

    expect(CampaignRecipient.find_by!(campaign: campaign, contact: contact)).to be_skipped
  end

  describe 'interrupted campaign recovery' do
    let(:service) { Whatsapp::OneoffCampaignService.new(campaign: campaign) }

    it 'commits recovery eligibility before executing the campaign' do
      allow(campaign).to receive(:execute_campaign).and_raise(Interrupt, 'worker terminated before enqueue')

      expect { campaign.trigger! }.to raise_error(Interrupt, 'worker terminated before enqueue')
      expect(campaign.reload).to have_attributes(campaign_status: 'processing', whatsapp_cursor: 0)
      campaign.update!(updated_at: 16.minutes.ago)

      expect { Campaigns::RecoverWhatsappCampaignsJob.perform_now }
        .to have_enqueued_job(Campaigns::SendWhatsappBatchJob).with(campaign, 0)
    end

    it 'does not repeat an accepted send when the response is lost and continues untouched contacts' do
      stub_const('Whatsapp::OneoffCampaignService::BATCH_SIZE', 2)
      contacts = create_list(:contact, 3, :with_phone_number, account: account)
      contacts.each { |contact| contact.update_labels([label.title]) }
      destinations = []
      allow(whatsapp_channel).to receive(:send_template) do |destination, _template, _message|
        destinations << destination
        raise Interrupt, 'response lost after acceptance' if destinations.one?

        "wamid.#{destination}"
      end
      campaign.trigger!

      expect { service.perform_batch(0) }.to raise_error(Interrupt, 'response lost after acceptance')
      expect(campaign.reload.whatsapp_cursor).to eq(0)
      interrupted = campaign.campaign_recipients.find_by!(contact: contacts.first)
      expect(interrupted).to have_attributes(status: 'queued', source_id: nil, send_attempted_at: be_present)

      Campaigns::SendWhatsappBatchJob.perform_now(campaign, 0)
      Campaigns::SendWhatsappBatchJob.perform_now(campaign, 0)

      expect(destinations).to eq(contacts.map(&:phone_number))
      expect(campaign.reload).to be_completed
      expect(campaign.campaign_recipients.sent.count).to eq(2)
      expect(interrupted.reload.error_message).to include('Send outcome unknown')
    end

    it 'recovers a lost handoff using the saved cursor even when an old job is replayed' do
      stub_const('Whatsapp::OneoffCampaignService::BATCH_SIZE', 1)
      contacts = create_list(:contact, 2, :with_phone_number, account: account)
      contacts.each { |contact| contact.update_labels([label.title]) }
      allow(whatsapp_channel).to receive(:send_template).and_return('wamid.first', 'wamid.second')
      campaign.trigger!
      allow(Campaigns::SendWhatsappBatchJob).to receive(:perform_later).and_raise(StandardError, 'queue unavailable')

      expect { Campaigns::SendWhatsappBatchJob.perform_now(campaign) }.to raise_error(StandardError, 'queue unavailable')
      expect(campaign.reload.whatsapp_cursor).to eq(contacts.first.id)
      campaign.update!(updated_at: 16.minutes.ago)
      allow(Campaigns::SendWhatsappBatchJob).to receive(:perform_later).and_call_original

      expect { Campaigns::RecoverWhatsappCampaignsJob.perform_now }
        .to have_enqueued_job(Campaigns::SendWhatsappBatchJob).with(campaign, contacts.first.id)
      Campaigns::SendWhatsappBatchJob.perform_now(campaign, 0)
      Campaigns::SendWhatsappBatchJob.perform_now(campaign, 0)

      expect(whatsapp_channel).to have_received(:send_template).exactly(2).times
      expect(campaign.campaign_recipients.sent.count).to eq(2)
      expect(campaign.reload).to be_completed
    end

    it 'does not resend an in-flight recipient when another worker acquires an expired lease' do
      stub_const('Whatsapp::OneoffCampaignService::BATCH_SIZE', 2)
      contacts = create_list(:contact, 3, :with_phone_number, account: account)
      contacts.each { |contact| contact.update_labels([label.title]) }
      destinations = []
      campaign.trigger!
      allow(whatsapp_channel).to receive(:send_template) do |destination, _template, _message|
        destinations << destination
        if destinations.one?
          key = format(Redis::Alfred::WHATSAPP_CAMPAIGN_MUTEX, campaign_id: campaign.id)
          Redis::Alfred.expire(key, 0)
          Campaigns::SendWhatsappBatchJob.perform_now(Campaign.find(campaign.id))
        end
        "wamid.#{destination}"
      end

      Campaigns::SendWhatsappBatchJob.perform_now(campaign)
      Campaigns::SendWhatsappBatchJob.perform_now(campaign)

      expect(destinations).to eq(contacts.map(&:phone_number))
      expect(campaign.campaign_recipients.sent.count).to eq(3)
      expect(campaign.campaign_recipients.queued).to be_empty
      expect(campaign.reload).to be_completed
    end

    it 'does not rewind the checkpoint when a worker finishes after its lease expires' do
      stub_const('Whatsapp::OneoffCampaignService::BATCH_SIZE', 1)
      contacts = create_list(:contact, 2, :with_phone_number, account: account)
      contacts.each { |contact| contact.update_labels([label.title]) }
      campaign.trigger!
      allow(whatsapp_channel).to receive(:send_template).and_return('wamid.first', 'wamid.second')
      replacement = Campaign.find(campaign.id)
      replacement_service = Whatsapp::OneoffCampaignService.new(campaign: replacement)
      allow(service).to receive(:process_contacts).and_wrap_original do |process, batch|
        process.call(batch)
        key = format(Redis::Alfred::WHATSAPP_CAMPAIGN_MUTEX, campaign_id: campaign.id)
        Redis::Alfred.expire(key, 0)
        replacement.update!(whatsapp_cursor: contacts.first.id)
        Campaigns::SendWhatsappBatchJob.perform_now(replacement, contacts.first.id)
      end
      allow(Whatsapp::OneoffCampaignService).to receive(:new).and_return(service, replacement_service)

      Campaigns::SendWhatsappBatchJob.perform_now(campaign)

      expect(campaign.reload.whatsapp_cursor).to eq(contacts.last.id)
      expect(whatsapp_channel).to have_received(:send_template).exactly(2).times
      expect(campaign.campaign_recipients.sent.count).to eq(2)
    end

    it 'excludes historical queued, sent and failed recipients when a legacy batch is retried' do
      contacts = create_list(:contact, 4, :with_phone_number, account: account)
      contacts.each { |contact| contact.update_labels([label.title]) }
      campaign.processing!
      campaign.update!(whatsapp_cursor: nil)
      queued = campaign.campaign_recipients.create!(account: account, inbox: whatsapp_inbox, contact: contacts.first)
      campaign.campaign_recipients.create!(account: account, inbox: whatsapp_inbox, contact: contacts.second, status: :failed)
      campaign.campaign_recipients.create!(account: account, inbox: whatsapp_inbox, contact: contacts.third,
                                           status: :sent, source_id: 'wamid.existing')
      allow(whatsapp_channel).to receive(:send_template) do |destination, _template, _message|
        "wamid.#{destination}"
      end

      Campaigns::SendWhatsappBatchJob.perform_now(campaign)

      expect(whatsapp_channel).to have_received(:send_template).with(contacts.last.phone_number, anything, nil).once
      expect(whatsapp_channel).to have_received(:send_template).once
      expect(queued.reload).to have_attributes(status: 'queued', send_attempted_at: nil)
      expect(queued.error_message).to include('Send outcome unknown')
      expect(campaign.campaign_recipients.failed.count).to eq(1)
      expect(campaign.campaign_recipients.sent.count).to eq(2)
      expect(campaign.reload).to be_completed
    end
  end
end
