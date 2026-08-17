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

      it 'marks the campaign completed after processing the audience' do
        contact = create(:contact, :with_phone_number, account: account)
        contact.update_labels([label1.title])

        expect(whatsapp_channel).to receive(:send_template) do
          expect(campaign.reload.completed?).to be false
        end

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

      it 'skips contacts without a phone number or a business scoped user id' do
        contact_without_phone = create(:contact, account: account, phone_number: nil)
        contact_without_phone.update_labels([label1.title])

        expect(whatsapp_channel).not_to receive(:send_template)

        described_class.new(campaign: campaign).perform
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

        contact_drop_name = ContactDrop.new(contact).name

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
                  hash_including(type: 'text', parameter_name: 'name', text: contact_drop_name),
                  hash_including(type: 'text', parameter_name: 'ticket_id', text: contact.email)
                )
              )
            )
          ),
          nil
        )

        described_class.new(campaign: campaign_with_liquid).perform
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

        expect(whatsapp_channel).not_to receive(:send_template)
        expect(Rails.logger).to receive(:info).with("Skipping contact #{contact.name} - liquid variables resolved to blank values")
        allow(Rails.logger).to receive(:info)

        described_class.new(campaign: campaign_with_blank_liquid).perform
      end
    end

    context 'when the contact has a business scoped user id' do
      def contact_in_audience(phone_number: nil)
        contact = create(:contact, account: account, phone_number: phone_number)
        contact.update_labels([label1.title])
        contact
      end

      it 'addresses a contact that only has a business scoped user id' do
        contact = contact_in_audience
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'BR.5aBcD1')

        expect(whatsapp_channel).to receive(:send_template).with('BR.5aBcD1', anything, nil)

        described_class.new(campaign: campaign).perform
      end

      it 'keeps addressing by phone number when the contact has both' do
        contact = contact_in_audience(phone_number: '+555199999999')
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'BR.5aBcD1')

        expect(whatsapp_channel).to receive(:send_template).with('+555199999999', anything, nil)

        described_class.new(campaign: campaign).perform
      end

      it 'prefers the most recent identifier, since it rotates on a phone number change' do
        contact = contact_in_audience
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'BR.retired1')
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'BR.current1')

        expect(whatsapp_channel).to receive(:send_template).with('BR.current1', anything, nil)

        described_class.new(campaign: campaign).perform
      end

      it 'addresses the identifier scoped to this business when a payload carries both' do
        contact = contact_in_audience
        # The inbound path appends the parent identifier before the regular one, so the regular
        # identifier is the newer row whenever both arrive together.
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'BR.ENT.9zYxW2')
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'BR.5aBcD1')

        expect(whatsapp_channel).to receive(:send_template).with('BR.5aBcD1', anything, nil)

        described_class.new(campaign: campaign).perform
      end

      it 'addresses a current parent identifier rather than a regular one left behind by a rotation' do
        contact = contact_in_audience
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'BR.retired1')
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'BR.ENT.9zYxW2')

        expect(whatsapp_channel).to receive(:send_template).with('BR.ENT.9zYxW2', anything, nil)

        described_class.new(campaign: campaign).perform
      end

      it 'falls back to the parent identifier when it is the only one' do
        contact = contact_in_audience
        create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'BR.ENT.9zYxW2')

        expect(whatsapp_channel).to receive(:send_template).with('BR.ENT.9zYxW2', anything, nil)

        described_class.new(campaign: campaign).perform
      end

      it 'ignores an identifier that belongs to another inbox' do
        other_inbox = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                                validate_provider_config: false, sync_templates: false).inbox
        contact = contact_in_audience
        create(:contact_inbox, contact: contact, inbox: other_inbox, source_id: 'BR.5aBcD1')

        expect(whatsapp_channel).not_to receive(:send_template)

        described_class.new(campaign: campaign).perform
      end

      # A campaign walks its recipients one at a time, so reading the identifier per contact would
      # cost one round trip each on a queue that is already low priority.
      def count_contact_inbox_queries(&)
        count = 0
        counter = ->(_name, _start, _finish, _id, payload) { count += 1 if payload[:sql].to_s.include?('FROM "contact_inboxes"') }
        ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
        count
      end

      it 'reads the identifiers for the whole audience in a single query' do
        3.times do |index|
          contact = contact_in_audience
          create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: "BR.bulk#{index}")
        end
        allow(whatsapp_channel).to receive(:send_template)

        queries = count_contact_inbox_queries { described_class.new(campaign: campaign).perform }

        expect(queries).to eq(1)
      end

      it 'reads no identifier at all when every contact has a phone number' do
        3.times { |index| contact_in_audience(phone_number: "+5551999999#{index}9") }
        allow(whatsapp_channel).to receive(:send_template)

        queries = count_contact_inbox_queries { described_class.new(campaign: campaign).perform }

        expect(queries).to eq(0)
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
      it 'logs error and continues processing remaining contacts' do
        contact_error, contact_success = create_list(:contact, 2, :with_phone_number, account: account)
        contact_error.update_labels([label1.title])
        contact_success.update_labels([label1.title])
        error_message = 'WhatsApp API error'

        allow(whatsapp_channel).to receive(:send_template).and_return(nil)

        expect(whatsapp_channel).to receive(:send_template).with(contact_error.phone_number, anything, nil).and_raise(StandardError, error_message)
        expect(whatsapp_channel).to receive(:send_template).with(contact_success.phone_number, anything, nil).once

        expect(Rails.logger).to receive(:error)
          .with("Failed to send WhatsApp template message to #{contact_error.phone_number}: #{error_message}")
        expect(Rails.logger).to receive(:error).with(/Backtrace:/)

        described_class.new(campaign: campaign).perform
        expect(campaign.reload.completed?).to be true
      end
    end
  end
end
