require 'rails_helper'

# rubocop:disable RSpec/SpecFilePathFormat
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
# rubocop:enable RSpec/SpecFilePathFormat
