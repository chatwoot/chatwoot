require 'rails_helper'

# rubocop:disable RSpec/MultipleDescribes
RSpec.describe Whatsapp::Providers::WhatsappCloudService, '#send_message with a reply-button snapshot' do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }
  let(:snapshot) { JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/button.json').read) }
  let(:message) do
    create(
      :message,
      conversation: conversation,
      inbox: whatsapp_channel.inbox,
      message_type: :outgoing,
      content: snapshot.dig('body', 'text'),
      content_attributes: { whatsapp_interactive: snapshot }
    )
  end

  it 'uses the configured Graph version and maps the stored snapshot exactly' do
    allow(GlobalConfigService).to receive(:load).with('WHATSAPP_API_VERSION', 'v22.0').and_return('v25.0')
    request = stub_request(:post, 'https://graph.facebook.com/v25.0/123456789/messages')
              .with(
                body: {
                  messaging_product: 'whatsapp',
                  to: '+15550000001',
                  interactive: {
                    type: 'button',
                    body: { text: 'Please choose one option.' },
                    action: {
                      buttons: [
                        {
                          type: 'reply',
                          reply: { id: 'reply_00000000-0000-4000-8000-000000000001', title: 'Confirm' }
                        },
                        {
                          type: 'reply',
                          reply: { id: 'reply_00000000-0000-4000-8000-000000000002', title: 'Change' }
                        }
                      ]
                    }
                  },
                  type: 'interactive'
                }.to_json
              )
              .to_return(status: 200, body: { messages: [{ id: 'message_id' }] }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(service.send_message('+15550000001', message)).to eq('message_id')
    expect(request).to have_been_requested.once
  end
end

RSpec.describe Whatsapp::Providers::WhatsappCloudService, '#send_message with a list snapshot' do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:snapshot) { JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/list.json').read) }
  let(:message) do
    create(
      :message,
      conversation: create(:conversation, inbox: whatsapp_channel.inbox),
      inbox: whatsapp_channel.inbox,
      message_type: :outgoing,
      content: snapshot.dig('body', 'text'),
      content_attributes: { whatsapp_interactive: snapshot }
    )
  end

  it 'dispatches the stored hierarchy as one native list request' do
    expected = Whatsapp::InteractiveMessages::Registry.provider_payload(snapshot)
    request = stub_request(:post, 'https://graph.facebook.com/v22.0/123456789/messages')
              .with(body: hash_including(type: 'interactive', interactive: expected))
              .to_return(
                status: 200,
                body: { messages: [{ id: 'message_id' }] }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )

    expect(service.send_message('+15550000001', message)).to eq('message_id')
    expect(request).to have_been_requested.once
  end
end

RSpec.describe Whatsapp::Providers::WhatsappCloudService, '#send_message with a CTA URL snapshot' do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:snapshot) { JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/cta_url.json').read) }
  let(:message) do
    create(
      :message,
      conversation: create(:conversation, inbox: whatsapp_channel.inbox),
      inbox: whatsapp_channel.inbox,
      message_type: :outgoing,
      content: snapshot.dig('body', 'text'),
      content_attributes: { whatsapp_interactive: snapshot }
    )
  end

  it 'dispatches the stored CTA as one native request without click identity' do
    request = stub_request(:post, 'https://graph.facebook.com/v22.0/123456789/messages')
              .with(
                body: hash_including(
                  type: 'interactive',
                  interactive: {
                    type: 'cta_url',
                    header: { type: 'text', text: 'Order update' },
                    body: { text: 'Your order is ready to review.' },
                    footer: { text: 'Secure link' },
                    action: {
                      name: 'cta_url',
                      parameters: { display_text: 'View details', url: 'https://example.test/details' }
                    }
                  }
                )
              )
              .to_return(
                status: 200,
                body: { messages: [{ id: 'message_id' }] }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )

    expect(service.send_message('+15550000001', message)).to eq('message_id')
    expect(request).to have_been_requested.once
  end
end
# rubocop:enable RSpec/MultipleDescribes
