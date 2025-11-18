require 'rails_helper'

describe Whatsapp::OneoffCampaignService do
  let(:account) { create(:account) }
  let!(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let!(:whatsapp_inbox) { whatsapp_channel.inbox }
  let(:label1) { create(:label, account: account) }
  let(:label2) { create(:label, account: account) }
  let!(:campaign) do
    create(:campaign, inbox: whatsapp_inbox, account: account,
                      audience: [{ type: 'Label', id: label1.id }, { type: 'Label', id: label2.id }],
                      template_params: template_params)
  end
  let(:template_params) do
    {
      'name' => 'ticket_status_updated',
      'namespace' => '23423423_2342423_324234234_2343224',
      'category' => 'UTILITY',
      'language' => 'en',
      'processed_params' => { 'body' => { 'name' => 'John', 'ticket_id' => '2332' } }
    }
  end

  before do
    # Stub HTTP requests to WhatsApp API
    stub_request(:post, /graph\.facebook\.com.*messages/)
      .to_return(status: 200, body: { messages: [{ id: 'message_id_123' }] }.to_json, headers: { 'Content-Type' => 'application/json' })

    # Ensure the service uses our mocked channel object by stubbing the whole delegation chain
    # Using allow_any_instance_of here because the service is instantiated within individual tests
    # and we need to mock the delegated channel method for proper test isolation
    allow_any_instance_of(described_class).to receive(:channel).and_return(whatsapp_channel) # rubocop:disable RSpec/AnyInstance
  end

  describe '#perform' do
    before do
      # Enable WhatsApp campaigns feature flag for all tests
      account.enable_features!(:whatsapp_campaign)
    end

    context 'when campaign validation fails' do
      it 'raises error if campaign is completed' do
        campaign.completed!

        expect { described_class.new(campaign: campaign).perform }.to raise_error 'Completed Campaign'
      end

      it 'raises error when campaign is not a WhatsApp campaign' do
        sms_channel = create(:channel_sms, account: account)
        sms_inbox = create(:inbox, channel: sms_channel, account: account)
        invalid_campaign = create(:campaign, inbox: sms_inbox, account: account)

        expect { described_class.new(campaign: invalid_campaign).perform }
          .to raise_error "Invalid campaign #{invalid_campaign.id}"
      end

      it 'raises error when campaign is not oneoff' do
        allow(campaign).to receive(:one_off?).and_return(false)

        expect { described_class.new(campaign: campaign).perform }.to raise_error "Invalid campaign #{campaign.id}"
      end

      it 'raises error when channel provider is not whatsapp_cloud' do
        whatsapp_channel.update!(provider: 'default')

        expect { described_class.new(campaign: campaign).perform }.to raise_error 'WhatsApp Cloud provider required'
      end

      it 'raises error when WhatsApp campaigns feature is not enabled' do
        account.disable_features!(:whatsapp_campaign)

        expect { described_class.new(campaign: campaign).perform }.to raise_error 'WhatsApp campaigns feature not enabled'
      end
    end

    context 'when campaign is valid' do
      it 'marks campaign as completed' do
        described_class.new(campaign: campaign).perform

        expect(campaign.reload.completed?).to be true
      end

      it 'processes contacts with matching labels' do
        contact_with_label1, contact_with_label2, contact_with_both_labels =
          create_list(:contact, 3, :with_phone_number, account: account)
        contact_with_label1.update_labels([label1.title])
        contact_with_label2.update_labels([label2.title])
        contact_with_both_labels.update_labels([label1.title, label2.title])

        expect(whatsapp_channel).to receive(:send_template).exactly(3).times

        described_class.new(campaign: campaign).perform
      end

      it 'skips contacts without phone numbers' do
        contact_without_phone = create(:contact, account: account, phone_number: nil)
        contact_without_phone.update_labels([label1.title])

        expect(whatsapp_channel).not_to receive(:send_template)

        described_class.new(campaign: campaign).perform
      end

      it 'skips contacts with phone numbers longer than 15 digits' do
        contact_invalid = create(:contact, :with_phone_number, account: account)
        contact_invalid.update_labels([label1.title])
        # Update phone to invalid value bypassing validations
        contact_invalid.update_column(:phone_number, '+1234567890123456789')

        expect(whatsapp_channel).not_to receive(:send_template)
        expect(Rails.logger).to receive(:warn).with(/Invalid phone format/)

        described_class.new(campaign: campaign).perform

        campaign_contact = campaign.campaign_contacts.find_by(contact: contact_invalid)
        expect(campaign_contact.status).to eq('skipped')
        expect(campaign_contact.error_message).to match(/Invalid phone format/)
      end

      it 'skips contacts with invalid phone number format' do
        contact_invalid = create(:contact, :with_phone_number, account: account)
        contact_invalid.update_labels([label1.title])
        # Update phone to invalid value bypassing validations
        contact_invalid.update_column(:phone_number, '+++')

        expect(whatsapp_channel).not_to receive(:send_template)
        expect(Rails.logger).to receive(:warn).with(/Invalid phone format/)

        described_class.new(campaign: campaign).perform

        campaign_contact = campaign.campaign_contacts.find_by(contact: contact_invalid)
        expect(campaign_contact.status).to eq('skipped')
        expect(campaign_contact.error_message).to match(/Invalid phone format/)
      end

      it 'uses template processor service to process templates' do
        contact = create(:contact, :with_phone_number, account: account)
        contact.update_labels([label1.title])

        expect(Whatsapp::TemplateProcessorService).to receive(:new)
          .with(channel: whatsapp_channel, template_params: template_params)
          .and_call_original

        described_class.new(campaign: campaign).perform
      end

      it 'sends template message with correct parameters' do
        contact = create(:contact, :with_phone_number, account: account)
        contact.update_labels([label1.title])

        expect(whatsapp_channel).to receive(:send_template).with(
          contact.phone_number,
          hash_including(
            name: 'ticket_status_updated',
            namespace: '23423423_2342423_324234234_2343224',
            lang_code: 'en',
            parameters: array_including(
              hash_including(
                type: 'body',
                parameters: array_including(
                  hash_including(type: 'text', parameter_name: 'name', text: 'John'),
                  hash_including(type: 'text', parameter_name: 'ticket_id', text: '2332')
                )
              )
            )
          ),
          nil
        )

        described_class.new(campaign: campaign).perform
      end
    end

    context 'when template_params is missing' do
      let(:template_params) { nil }

      it 'skips contacts and logs error' do
        contact = create(:contact, :with_phone_number, account: account)
        contact.update_labels([label1.title])

        expect(Rails.logger).to receive(:error)
          .with("Skipping contact #{contact.name} - no template_params found for WhatsApp campaign")
        expect(whatsapp_channel).not_to receive(:send_template)

        described_class.new(campaign: campaign).perform
      end
    end

    context 'when send_template raises an error' do
      it 'marks contact as failed and continues processing remaining contacts' do
        contact_error, contact_success = create_list(:contact, 2, :with_phone_number, account: account)
        contact_error.update_labels([label1.title])
        contact_success.update_labels([label1.title])
        error_message = 'WhatsApp API error'

        allow(whatsapp_channel).to receive(:send_template).and_return('message_id_123')
        expect(whatsapp_channel).to receive(:send_template)
          .with(contact_error.phone_number, anything, nil)
          .and_raise(StandardError.new(error_message))
        expect(whatsapp_channel).to receive(:send_template)
          .with(contact_success.phone_number, anything, nil)
          .and_return('message_id_456')

        expect(Rails.logger).to receive(:error)
          .with("Failed to send WhatsApp template message to #{contact_error.phone_number}: StandardError: #{error_message}")
        expect(Rails.logger).to receive(:error).with(/Backtrace:/)

        described_class.new(campaign: campaign).perform

        campaign_contact_error = campaign.campaign_contacts.find_by(contact: contact_error)
        campaign_contact_success = campaign.campaign_contacts.find_by(contact: contact_success)

        expect(campaign_contact_error.status).to eq('failed')
        expect(campaign_contact_success.status).to eq('sent')
        expect(campaign.reload.completed?).to be true
      end
    end

    context 'when DB operations fail after successful send' do
      it 'marks contact as sent but logs DB error' do
        contact = create(:contact, :with_phone_number, account: account)
        contact.update_labels([label1.title])

        allow(whatsapp_channel).to receive(:send_template).and_return('message_id_123')
        allow_any_instance_of(described_class).to receive(:find_or_create_contact_inbox) # rubocop:disable RSpec/AnyInstance
          .and_raise(ActiveRecord::RecordInvalid.new(ContactInbox.new))

        # Allow any other log messages
        allow(Rails.logger).to receive(:info).and_call_original
        allow(Rails.logger).to receive(:error).and_call_original

        # Expect specific log messages
        expect(Rails.logger).to receive(:info)
          .with("WhatsApp message sent successfully to #{contact.phone_number}, message_id: message_id_123").once
        expect(Rails.logger).to receive(:error)
          .with(/Message sent but failed to create DB records/).once

        described_class.new(campaign: campaign).perform

        campaign_contact = campaign.campaign_contacts.find_by(contact: contact)
        expect(campaign_contact.status).to eq('sent')
        expect(campaign.reload.completed?).to be true
      end
    end
  end
end
