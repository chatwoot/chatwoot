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

RSpec.describe Whatsapp::Providers::WhatsappCloudService, '#send_message with a carousel snapshot' do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:message) do
    create(
      :message,
      conversation: create(:conversation, inbox: whatsapp_channel.inbox),
      inbox: whatsapp_channel.inbox,
      message_type: :outgoing,
      content: 'Choose a destination.'
    )
  end
  let!(:attachments) do
    Array.new(2) do
      message.attachments.create!(
        account_id: message.account_id,
        file_type: :image,
        file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
      )
    end
  end

  before do
    attachments.each_with_index do |attachment, index|
      allow(attachment).to receive(:download_url).and_return("https://trusted.test/card-#{index}")
    end
    allow(message.attachments).to receive(:where)
      .with(id: attachments.pluck(:id), account_id: message.account_id)
      .and_return(attachments)
  end

  it 'dispatches every ordered URL card as one native carousel request without response identity' do
    snapshot = JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/carousel_url.json').read)
    snapshot.dig('action', 'cards').each_with_index { |card, index| card['header']['attachment_id'] = attachments[index].id }
    message.update!(content_attributes: { whatsapp_interactive: snapshot })
    expected = Whatsapp::InteractiveMessages::Registry.provider_payload(snapshot, attachments: attachments)
    request = stub_request(:post, 'https://graph.facebook.com/v22.0/123456789/messages')
              .with(body: hash_including(type: 'interactive', interactive: expected))
              .to_return(
                status: 200,
                body: { messages: [{ id: 'message_id' }] }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )

    expect(service.send_message('+15550000001', message)).to eq('message_id')
    expect(request).to have_been_requested.once
    expect(expected.to_json).not_to include('delivery_id', 'quick_reply')
  end

  it 'dispatches card-local quick replies whose IDs remain unique across the native carousel' do
    snapshot = JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/carousel_quick_reply.json').read)
    snapshot.dig('action', 'cards').each_with_index { |card, index| card['header']['attachment_id'] = attachments[index].id }
    message.update!(content_attributes: { whatsapp_interactive: snapshot })
    expected = Whatsapp::InteractiveMessages::Registry.provider_payload(snapshot, attachments: attachments)
    request = stub_request(:post, 'https://graph.facebook.com/v22.0/123456789/messages')
              .with(body: hash_including(type: 'interactive', interactive: expected))
              .to_return(
                status: 200,
                body: { messages: [{ id: 'message_id' }] }.to_json,
                headers: { 'Content-Type' => 'application/json' }
              )

    expect(service.send_message('+15550000001', message)).to eq('message_id')
    expect(request).to have_been_requested.once
    quick_replies = expected.dig(:action, :cards).flat_map { |card| card.dig(:action, :buttons) }.pluck(:quick_reply)
    expect(quick_replies.pluck(:id).uniq.length).to eq(4)
  end

  it 'rejects a stored card that references non-message-owned media before provider contact' do
    snapshot = JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/carousel_url.json').read)
    other_message = create(:message, account: message.account, inbox: message.inbox)
    unrelated = other_message.attachments.create!(
      account_id: message.account_id,
      file_type: :image,
      file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
    )
    snapshot.dig('action', 'cards', 0, 'header')['attachment_id'] = attachments.first.id
    snapshot.dig('action', 'cards', 1, 'header')['attachment_id'] = unrelated.id
    message.update!(content_attributes: { whatsapp_interactive: snapshot })
    allow(message.attachments).to receive(:where).and_call_original

    expect { service.send_message('+15550000001', message) }
      .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /unavailable or mismatched/)
    expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
  end
end
# rubocop:enable RSpec/MultipleDescribes
