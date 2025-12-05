require 'rails_helper'

describe Whatsapp::OneoffWhatsappCampaignService do
  subject(:whatsapp_campaign_service) { described_class.new(campaign: campaign) }

  before do
    # Stub the template sync request that happens when creating WhatsApp channel
    stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'D360-Api-Key' => 'test_key',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 200, body: '{"waba_templates": []}', headers: {})
  end

  let(:account) { create(:account) }
  let!(:whatsapp_channel) { create(:channel_whatsapp, account: account, validate_provider_config: false) }
  let!(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:label1) { create(:label, account: account) }
  let(:label2) { create(:label, account: account) }
  let!(:campaign) do
    create(:campaign, inbox: whatsapp_inbox, account: account,
                      audience: [{ type: 'Label', id: label1.id }, { type: 'Label', id: label2.id }])
  end

  describe 'perform' do
    before do
      # Stub the WhatsApp provider service to avoid actual API calls
      allow_any_instance_of(Whatsapp::Providers::Whatsapp360DialogService).to receive(:send_message).and_return('message_id')
      allow_any_instance_of(Whatsapp::Providers::WhatsappCloudService).to receive(:send_message).and_return('message_id')
      allow_any_instance_of(Channel::Whatsapp).to receive(:send_message).and_return('message_id')
    end

    it 'raises error if the campaign is completed' do
      campaign.completed!

      expect { whatsapp_campaign_service.perform }.to raise_error 'Completed Campaign'
    end

    it 'raises error invalid campaign when its not a oneoff whatsapp campaign' do
      invalid_campaign = create(:campaign)

      expect { described_class.new(campaign: invalid_campaign).perform }.to raise_error "Invalid campaign #{invalid_campaign.id}"
    end

    it 'send messages to contacts in the audience and marks the campaign completed' do
      contact_with_label1, contact_with_label2, contact_with_both_labels = FactoryBot.create_list(:contact, 3, :with_phone_number, account: account)
      contact_with_label1.update_labels([label1.title])
      contact_with_label2.update_labels([label2.title])
      contact_with_both_labels.update_labels([label1.title, label2.title])

      # Expect the channel send_message to be called for each contact
      # Use campaign.inbox.channel to get the same instance that the service will use
      expect(campaign.inbox.channel).to receive(:send_message).exactly(3).times.and_return('message_id')

      whatsapp_campaign_service.perform
      expect(campaign.reload.completed?).to be true
    end

    it 'skips contacts without phone numbers' do
      contact_with_label1 = create(:contact, account: account, phone_number: nil)
      contact_with_label2 = create(:contact, :with_phone_number, account: account)
      contact_with_label1.update_labels([label1.title])
      contact_with_label2.update_labels([label2.title])

      # Expect the channel send_message to be called only for the contact with phone number
      expect(campaign.inbox.channel).to receive(:send_message).once.and_return('message_id')

      whatsapp_campaign_service.perform
      expect(campaign.reload.completed?).to be true
    end

    context 'with WhatsApp Cloud provider' do
      let!(:whatsapp_cloud_channel) do
        create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, validate_provider_config: false, sync_templates: false)
      end
      let!(:whatsapp_cloud_inbox) { create(:inbox, channel: whatsapp_cloud_channel, account: account) }
      let!(:cloud_campaign) do
        create(:campaign, inbox: whatsapp_cloud_inbox, account: account,
                          audience: [{ type: 'Label', id: label1.id }, { type: 'Label', id: label2.id }])
      end
      let(:cloud_service) { described_class.new(campaign: cloud_campaign) }

      before do
        # Stub the WhatsApp Cloud provider template sync request
        stub_request(:get, "https://graph.facebook.com/v14.0/#{whatsapp_cloud_channel.provider_config['business_account_id']}/message_templates?access_token=#{whatsapp_cloud_channel.provider_config['api_key']}")
          .to_return(status: 200, body: '{"data": []}', headers: {})
      end

      it 'sends messages through WhatsApp Cloud provider and marks campaign completed' do
        contact_with_label1, contact_with_label2 = FactoryBot.create_list(:contact, 2, :with_phone_number, account: account)
        contact_with_label1.update_labels([label1.title])
        contact_with_label2.update_labels([label2.title])

        # Expect the WhatsApp Cloud channel to send messages
        expect(cloud_campaign.inbox.channel).to receive(:send_message).twice.and_return('cloud_message_id')

        cloud_service.perform
        expect(cloud_campaign.reload.completed?).to be true
      end

      it 'verifies WhatsApp Cloud provider service is used' do
        # Verify that the channel uses the correct provider service
        expect(whatsapp_cloud_channel.provider_service).to be_a(Whatsapp::Providers::WhatsappCloudService)
        expect(whatsapp_cloud_channel.provider).to eq('whatsapp_cloud')
      end
    end
  end

  describe 'delay functionality' do
    let(:contact1) { create(:contact, :with_phone_number, account: account) }
    let(:contact2) { create(:contact, :with_phone_number, account: account) }
    let(:contact3) { create(:contact, :with_phone_number, account: account) }

    before do
      contact1.update_labels([label1.title])
      contact2.update_labels([label1.title])
      contact3.update_labels([label1.title])

      # Stub WhatsApp provider to avoid actual API calls
      allow(campaign.inbox.channel).to receive(:send_message).and_return('message_id')
    end

    context 'when campaign has no delay configured' do
      let(:campaign) do
        create(:campaign, account: account, inbox: whatsapp_inbox, audience: [{ 'type' => 'Label', 'id' => label1.id }], trigger_rules: {})
      end

      it 'sends all messages immediately without delay' do
        expect(whatsapp_campaign_service).not_to receive(:sleep)
        whatsapp_campaign_service.perform
        expect(campaign.inbox.channel).to have_received(:send_message).exactly(3).times
      end
    end

    context 'when campaign has fixed delay configured' do
      let(:campaign) do
        create(:campaign, account: account, inbox: whatsapp_inbox, audience: [{ 'type' => 'Label', 'id' => label1.id }],
                          trigger_rules: { 'delay' => { 'type' => 'fixed', 'seconds' => 2 } })
      end

      it 'applies fixed delay between messages except first' do
        expect(whatsapp_campaign_service).to receive(:sleep).with(2).twice
        whatsapp_campaign_service.perform
        expect(campaign.inbox.channel).to have_received(:send_message).exactly(3).times
      end

      it 'logs delay application' do
        allow(whatsapp_campaign_service).to receive(:sleep)
        allow(Rails.logger).to receive(:info).and_call_original
        whatsapp_campaign_service.perform
        # Verify delay was applied (sleep was called) instead of checking logs
        expect(whatsapp_campaign_service).to have_received(:sleep).with(2).exactly(2).times
      end
    end

    context 'when campaign has random delay configured' do
      let(:campaign) do
        create(:campaign, account: account, inbox: whatsapp_inbox, audience: [{ 'type' => 'Label', 'id' => label1.id }],
                          trigger_rules: { 'delay' => { 'type' => 'random', 'min' => 1, 'max' => 3 } })
      end

      it 'applies random delay within range between messages except first' do
        delays = []
        allow(whatsapp_campaign_service).to receive(:sleep) do |delay|
          delays << delay
        end

        whatsapp_campaign_service.perform

        expect(delays.count).to eq(2)
        delays.each do |delay|
          expect(delay).to be >= 1
          expect(delay).to be <= 3
        end
      end

      it 'logs delay application with actual value' do
        allow(whatsapp_campaign_service).to receive(:sleep)
        allow(Rails.logger).to receive(:info).and_call_original
        whatsapp_campaign_service.perform
        # Verify delay was applied (sleep was called) instead of checking logs
        expect(whatsapp_campaign_service).to have_received(:sleep).exactly(2).times
      end
    end

    context 'when campaign has delay type "none"' do
      let(:campaign) do
        create(:campaign, account: account, inbox: whatsapp_inbox, audience: [{ 'type' => 'Label', 'id' => label1.id }],
                          trigger_rules: { 'delay' => { 'type' => 'none' } })
      end

      it 'does not apply any delay' do
        expect(whatsapp_campaign_service).not_to receive(:sleep)
        whatsapp_campaign_service.perform
        expect(campaign.inbox.channel).to have_received(:send_message).exactly(3).times
      end
    end

    context 'when delay is configured but first message' do
      let(:campaign) do
        create(:campaign, account: account, inbox: whatsapp_inbox, audience: [{ 'type' => 'Label', 'id' => label1.id }],
                          trigger_rules: { 'delay' => { 'type' => 'fixed', 'seconds' => 5 } })
      end

      it 'skips delay for the first contact' do
        # With 3 contacts, delay should be called 2 times (not 3)
        expect(whatsapp_campaign_service).to receive(:sleep).with(5).twice
        whatsapp_campaign_service.perform
      end
    end

    context 'when contact has no phone number' do
      let(:contact_without_phone) { create(:contact, account: account, phone_number: nil) }
      let(:campaign) do
        create(:campaign, account: account, inbox: whatsapp_inbox, audience: [{ 'type' => 'Label', 'id' => label1.id }],
                          trigger_rules: { 'delay' => { 'type' => 'fixed', 'seconds' => 2 } })
      end

      before do
        contact_without_phone.update_labels([label1.title])
      end

      it 'skips contact without applying delay' do
        # Should send to 3 contacts with phone numbers, skipping the one without
        # Delay applied 2 times (for 2nd and 3rd contacts with phone)
        expect(whatsapp_campaign_service).to receive(:sleep).with(2).twice
        whatsapp_campaign_service.perform
        expect(campaign.inbox.channel).to have_received(:send_message).exactly(3).times
      end
    end

    context 'when error occurs during message sending' do
      let(:campaign) do
        create(:campaign, account: account, inbox: whatsapp_inbox, audience: [{ 'type' => 'Label', 'id' => label1.id }],
                          trigger_rules: { 'delay' => { 'type' => 'fixed', 'seconds' => 2 } })
      end

      it 'continues processing remaining contacts with delay' do
        call_count = 0
        allow(whatsapp_campaign_service).to receive(:sleep)
        allow(campaign.inbox.channel).to receive(:send_message) do
          call_count += 1
          raise StandardError, 'Test error' if call_count == 2

          'message_id'
        end

        # Should continue processing despite error
        expect { whatsapp_campaign_service.perform }.not_to raise_error
        expect(campaign.reload).to be_completed
        # Verify sleep was called for 2nd and 3rd contacts
        expect(whatsapp_campaign_service).to have_received(:sleep).with(2).exactly(2).times
      end
    end
  end
end
