require 'rails_helper'

describe Whatsapp::OneoffWhatsappCampaignService do
  let(:account) { create(:account) }
  let!(:whatsapp_channel) { create(:channel_whatsapp, provider_config: { 'api_key' => 'test_key' }) }
  let!(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel) }
  let(:label1) { create(:label, account: account) }
  let(:label2) { create(:label, account: account) }
  let(:template_variables) { { '1' => 'Test' } }
  let!(:campaign) do
    create(:campaign, inbox: whatsapp_inbox, account: account,
                      audience: [{ type: 'Label', id: label1.id }, { type: 'Label', id: label2.id }],
                      whatsapp_template: 'template_id', template_variables: template_variables)
  end

  before do
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      .with(
        body: "{\"url\":\"http://localhost:3000/webhooks/whatsapp/#{whatsapp_channel.phone_number}\"}",
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'D360-Api-Key' => 'test_key',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 200, body: '', headers: {})

    stub_request(:post, 'https://waba.360dialog.io/v1/messages')
      .to_return(status: 200, body: { 'messages' => [{ 'id' => '123456789' }] }.to_json, headers: {})
  end

  describe '#perform' do
    it 'raises error if the campaign is completed' do
      campaign.completed!

      expect { described_class.new(campaign: campaign).perform }.to raise_error 'Completed Campaign'
    end

    it 'raises error for invalid campaign' do
      invalid_campaign = create(:campaign)

      expect { described_class.new(campaign: invalid_campaign).perform }.to raise_error "Invalid campaign #{invalid_campaign.id}"
    end

    it 'sends messages to contacts in the audience and marks the campaign completed' do
      contact_with_label1, contact_with_label2, contact_with_both_labels = FactoryBot.create_list(:contact, 3, :with_phone_number, account: account)
      contact_with_label1.update_labels([label1.title])
      contact_with_label2.update_labels([label2.title])
      contact_with_both_labels.update_labels([label1.title, label2.title])

      described_class.new(campaign: campaign).perform

      assert_requested(:post, 'https://waba.360dialog.io/v1/messages', times: 3)
      expect(campaign.reload.completed?).to be true
    end
  end

  describe 'template processing' do
    let(:template) do
      {
        'id' => 'template_id',
        'name' => 'appointment_reminder',
        'namespace' => 'whatsapp:hsm:technology:xyz',
        'language' => 'en',
        'category' => 'TRANSACTIONAL',
        'components' => [
          {
            'type' => 'BODY',
            'text' => 'Hello {{name}}, your appointment is scheduled for {{appointment_date}}.'
          }
        ]
      }
    end

    before do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
        .with(
          body: "{\"url\":\"http://localhost:3000/webhooks/whatsapp/#{whatsapp_channel.phone_number}\"}",
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Content-Type' => 'application/json',
            'D360-Api-Key' => 'test_key',
            'User-Agent' => 'Ruby'
          }
        )
        .to_return(status: 200, body: '', headers: {})

      stub_request(:post, 'https://waba.360dialog.io/v1/messages')
        .to_return(status: 200, body: { 'messages' => [{ 'id' => '123456789' }] }.to_json, headers: {})
    end

    it 'fetches and processes the template correctly' do
      allow(whatsapp_channel).to receive(:message_templates).and_return([template])
      template_params = described_class.new(campaign: campaign).send(:template_params, template)
      expect(template_params).to eq(['appointment_reminder', 'whatsapp:hsm:technology:xyz', 'en', 'TRANSACTIONAL', template_variables])
    end
  end
end
