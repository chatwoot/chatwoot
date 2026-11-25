require 'rails_helper'

RSpec.describe Messages::DeleteOnChannelJob do
  subject(:job) { described_class.perform_later(message.id) }

  let(:account) { create(:account) }
  let(:channel) { create(:channel_whatsapp, provider: 'baileys', account: account, validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: account, phone_number: '+551187654321', identifier: nil) }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '551187654321') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }
  let(:message) do
    create(:message, message_type: :outgoing, conversation: conversation, account: account, inbox: inbox, source_id: 'wa_msg_123')
  end
  let(:delete_url) { "#{channel.provider_config['provider_url']}/connections/#{channel.phone_number}/messages" }

  it 'enqueues the job on the high queue' do
    expect { job }.to have_enqueued_job(described_class).on_queue('high')
  end

  it 'deletes the message on the channel' do
    delete_stub = stub_request(:delete, delete_url)
                  .with { |req| JSON.parse(req.body)['key'].slice('id', 'fromMe') == { 'id' => 'wa_msg_123', 'fromMe' => true } }
                  .to_return(status: 200, body: '{}')

    described_class.perform_now(message.id)

    expect(delete_stub).to have_been_requested
  end

  it 'does nothing when the message no longer exists' do
    delete_stub = stub_request(:delete, delete_url).to_return(status: 200, body: '{}')

    expect { described_class.perform_now(message.id + 1000) }.not_to raise_error
    expect(delete_stub).not_to have_been_requested
  end

  it 'does nothing when the message has no source_id' do
    delete_stub = stub_request(:delete, delete_url).to_return(status: 200, body: '{}')
    message.update!(source_id: nil)

    described_class.perform_now(message.id)

    expect(delete_stub).not_to have_been_requested
  end

  it 'does nothing when the channel does not support deletion' do
    web_widget_message = create(:message, message_type: :outgoing, source_id: 'some_id')
    delete_stub = stub_request(:delete, delete_url).to_return(status: 200, body: '{}')

    described_class.perform_now(web_widget_message.id)

    expect(delete_stub).not_to have_been_requested
  end

  it 'retries when the provider fails, so a hiccup does not leave the message alive on WhatsApp' do
    stub_request(:delete, delete_url).to_return(status: 500, body: 'provider down')
    # the provider service marks the connection as closed and tries to reconnect on any error
    stub_request(:post, "#{channel.provider_config['provider_url']}/connections/#{channel.phone_number}").to_return(status: 200)

    expect { described_class.perform_now(message.id) }.to have_enqueued_job(described_class).with(message.id)
  end
end
