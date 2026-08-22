require 'rails_helper'

describe Whatsapp::OneoffCampaignService do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let!(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let!(:whatsapp_inbox) { whatsapp_channel.inbox }
  let(:label1) { create(:label, account: account) }
  let(:label2) { create(:label, account: account) }
  let(:template_params) do
    {
      'name' => 'ticket_status_updated',
      'namespace' => '23423423_2342423_324234234_2343224',
      'category' => 'UTILITY',
      'language' => 'en',
      'processed_params' => { 'body' => { 'name' => 'John', 'ticket_id' => '2332' } }
    }
  end

  # Captured payloads of the outbound requests to the external APIs. The specs
  # run the real delivery code and assert on what it actually sent.
  let(:cloud_api_payloads) { [] }
  let(:companion_payloads) { [] }

  before do
    ActiveJob::Base.queue_adapter = :test

    stub_request(:post, /graph\.facebook\.com.*messages/)
      .with do |request|
      cloud_api_payloads << JSON.parse(request.body)
      true
    end
      .to_return(status: 200, body: { messages: [{ id: 'message_id_123' }] }.to_json,
                 headers: { 'Content-Type' => 'application/json' })

    stub_request(:post, 'http://whatsapp-companion:4000/send')
      .with do |request|
      companion_payloads << JSON.parse(request.body)
      true
    end
      .to_return(status: 200, body: { id: 'companion_message_id', status: 'sent' }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  describe '#perform' do
    before do
      # Enable WhatsApp campaigns feature flag for all tests
      account.enable_features!(:whatsapp_campaign)
    end

    context 'when campaign validation fails' do
      let(:campaign) do
        create(:campaign, inbox: whatsapp_inbox, account: account,
                          audience: [{ type: 'Label', id: label1.id }],
                          template_params: template_params)
      end

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
        campaign.update_columns(campaign_type: 'ongoing') # rubocop:disable Rails/SkipsModelValidations

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

    context 'when channel provider is whatsapp_unofficial' do
      let!(:unofficial_channel) do
        create(:channel_whatsapp, account: account, provider: 'whatsapp_unofficial',
                                  phone_number: '15550009999',
                                  validate_provider_config: false, sync_templates: false)
      end
      let!(:unofficial_inbox) { unofficial_channel.inbox }
      let!(:unofficial_campaign) do
        create(:campaign, inbox: unofficial_inbox, account: account,
                          audience: [{ type: 'Label', id: label1.id }],
                          message: 'Hello {{contact.name}}!')
      end

      before do
        # No feature flag required for unofficial sends.
        account.disable_features!(:whatsapp_campaign)
      end

      it 'sends a free-form liquid-rendered message through the companion' do
        contact = create(:contact, :with_phone_number, account: account, name: 'Jane')
        contact.update_labels([label1.title])

        perform_enqueued_jobs do
          described_class.new(campaign: unofficial_campaign).perform
        end

        expect(companion_payloads).to contain_exactly(
          'identifier' => '15550009999',
          'to' => contact.phone_number,
          'type' => 'text',
          'text' => 'Hello Jane!'
        )
        expect(cloud_api_payloads).to be_empty
        expect(unofficial_campaign.reload.completed?).to be true
      end
    end

    context 'when campaign is valid' do
      let(:campaign) do
        create(:campaign, inbox: whatsapp_inbox, account: account,
                          audience: [{ type: 'Label', id: label1.id }, { type: 'Label', id: label2.id }],
                          template_params: template_params)
      end

      it 'schedules delivery jobs for each contact instead of sending inline' do
        contact = create(:contact, :with_phone_number, account: account)
        contact.update_labels([label1.title])

        expect do
          described_class.new(campaign: campaign).perform
        end.to have_enqueued_job(Campaigns::WhatsappContactJob).with(campaign.id, contact.id)

        expect(campaign.reload.completed?).to be false
      end

      it 'schedules the correct number of delivery jobs' do
        create_list(:contact, 4, :with_phone_number, account: account).each { |c| c.update_labels([label1.title]) }

        expect do
          described_class.new(campaign: campaign).perform
        end.to have_enqueued_job(Campaigns::WhatsappContactJob).exactly(4).times

        expect(campaign.reload.completed?).to be false
      end

      it 'marks campaign as completed after all delivery jobs finish' do
        contact = create(:contact, :with_phone_number, account: account)
        contact.update_labels([label1.title])

        perform_enqueued_jobs do
          described_class.new(campaign: campaign).perform
        end

        expect(cloud_api_payloads).to contain_exactly(
          hash_including('to' => contact.phone_number, 'type' => 'template')
        )
        expect(campaign.reload.completed?).to be true
      end

      it 'processes contacts with matching labels' do
        contact_with_label1, contact_with_label2, contact_with_both_labels =
          create_list(:contact, 3, :with_phone_number, account: account)
        contact_with_label1.update_labels([label1.title])
        contact_with_label2.update_labels([label2.title])
        contact_with_both_labels.update_labels([label1.title, label2.title])

        perform_enqueued_jobs do
          described_class.new(campaign: campaign).perform
        end

        # Audience labels match inclusively: a contact holding any audience
        # label is a recipient.
        recipients = cloud_api_payloads.pluck('to')
        expect(recipients).to contain_exactly(
          contact_with_label1.phone_number,
          contact_with_label2.phone_number,
          contact_with_both_labels.phone_number
        )
      end

      it 'skips contacts without phone numbers' do
        contact_without_phone = create(:contact, account: account, phone_number: nil)
        contact_without_phone.update_labels([label1.title])

        perform_enqueued_jobs do
          described_class.new(campaign: campaign).perform
        end

        expect(cloud_api_payloads).to be_empty
      end

      it 'sends the template with the processed parameters' do
        contact = create(:contact, :with_phone_number, account: account)
        contact.update_labels([label1.title])

        perform_enqueued_jobs do
          described_class.new(campaign: campaign).perform
        end

        expect(cloud_api_payloads).to contain_exactly(
          hash_including(
            'to' => contact.phone_number,
            'type' => 'template',
            'template' => hash_including(
              'name' => 'ticket_status_updated',
              'language' => hash_including('code' => 'en'),
              'components' => [
                'type' => 'body',
                'parameters' => [
                  { 'type' => 'text', 'parameter_name' => 'name', 'text' => 'John' },
                  { 'type' => 'text', 'parameter_name' => 'ticket_id', 'text' => '2332' }
                ]
              ]
            )
          )
        )
      end

      it 'processes liquid variables in template parameters' do
        contact = create(:contact, :with_phone_number, account: account, name: 'Jane Smith', email: 'jane@example.com')
        contact.update_labels([label1.title])

        campaign_with_liquid = create(:campaign, inbox: whatsapp_inbox, account: account,
                                                 audience: [{ type: 'Label', id: label1.id }],
                                                 template_params: {
                                                   'name' => 'ticket_status_updated',
                                                   'namespace' => '23423423_2342423_324234234_2343224',
                                                   'category' => 'UTILITY',
                                                   'language' => 'en',
                                                   'processed_params' => {
                                                     'body' => {
                                                       'name' => '{{contact.name}}',
                                                       'ticket_id' => '{{contact.email}}'
                                                     }
                                                   }
                                                 })

        perform_enqueued_jobs do
          described_class.new(campaign: campaign_with_liquid).perform
        end

        body_parameters = cloud_api_payloads.first.dig('template', 'components').first['parameters']
        expect(body_parameters).to contain_exactly(
          { 'type' => 'text', 'parameter_name' => 'name', 'text' => ContactDrop.new(contact).name },
          { 'type' => 'text', 'parameter_name' => 'ticket_id', 'text' => 'jane@example.com' }
        )
      end

      it 'skips contacts when liquid variables resolve to blank values' do
        contact = create(:contact, :with_phone_number, account: account, name: 'Jane', email: nil)
        contact.update_labels([label1.title])

        campaign_with_blank_liquid = create(:campaign, inbox: whatsapp_inbox, account: account,
                                                       audience: [{ type: 'Label', id: label1.id }],
                                                       template_params: {
                                                         'name' => 'test_template',
                                                         'namespace' => 'test_namespace',
                                                         'language' => 'en',
                                                         'processed_params' => {
                                                           'body' => {
                                                             'email' => '{{contact.email}}'
                                                           }
                                                         }
                                                       })

        perform_enqueued_jobs do
          described_class.new(campaign: campaign_with_blank_liquid).perform
        end

        expect(cloud_api_payloads).to be_empty
      end

      it 'continues processing remaining contacts when a send fails' do
        contact_error, contact_success = create_list(:contact, 2, :with_phone_number, account: account)
        contact_error.update_labels([label1.title])
        contact_success.update_labels([label1.title])

        stub_request(:post, /graph\.facebook\.com.*messages/)
          .with { |request| JSON.parse(request.body)['to'] == contact_error.phone_number }
          .to_return(status: 500, body: { error: { message: 'WhatsApp API error' } }.to_json)

        perform_enqueued_jobs do
          described_class.new(campaign: campaign).perform
        end

        # Both contacts were attempted and the failed one did not stop the
        # campaign from completing.
        expect(a_request(:post, /graph\.facebook\.com.*messages/)
                 .with { |request| JSON.parse(request.body)['to'] == contact_error.phone_number }).to have_been_made.once
        expect(a_request(:post, /graph\.facebook\.com.*messages/)
                 .with { |request| JSON.parse(request.body)['to'] == contact_success.phone_number }).to have_been_made.once
        expect(campaign.reload.completed?).to be true
      end
    end

    context 'when template_params is missing' do
      let(:campaign) do
        create(:campaign, inbox: whatsapp_inbox, account: account,
                          audience: [{ type: 'Label', id: label1.id }],
                          template_params: nil)
      end

      it 'skips contacts without sending anything' do
        contact = create(:contact, :with_phone_number, account: account)
        contact.update_labels([label1.title])

        perform_enqueued_jobs do
          described_class.new(campaign: campaign).perform
        end

        expect(cloud_api_payloads).to be_empty
      end
    end
  end
end
