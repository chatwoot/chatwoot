require 'rails_helper'

RSpec.describe Whatsapp::Session::DeferredEventJob do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:chat) { model::Address.phone('5541999990000') }
  let(:edit) do
    payload = model::Events::MessageEdited.new(message_id: '3EB0LATE', chat: chat, timestamp: 1_755_440_000_000,
                                               content: model::Content::Text.new(body: 'corrigido'))
    model::Event.build(payload, id: 'evt-9', sid: channel.provider_config['session_id'], epoch: 1, seq: 9, ts: 1_755_440_000_000, inst: 'c')
  end

  it 'applies the edit once the message it refers to has been filed' do
    conversation = create(:conversation, inbox: inbox, account: inbox.account)
    message = create(:message, conversation: conversation, inbox: inbox, account: inbox.account, source_id: '3EB0LATE', content: 'original')

    described_class.perform_now(channel, edit.to_frame)

    expect(message.reload.content).to eq('corrigido')
  end

  it 'drops the event once the inbox holds another account' do
    conversation = create(:conversation, inbox: inbox, account: inbox.account)
    message = create(:message, conversation: conversation, inbox: inbox, account: inbox.account, source_id: '3EB0LATE', content: 'original')
    frame = edit.to_frame
    channel.update_columns(provider: 'uazapi', provider_config: { 'base_url' => 'https://uazapi.test', 'token' => 'x' }) # rubocop:disable Rails/SkipsModelValidations

    described_class.perform_now(channel, frame)

    expect(message.reload.content).to eq('original')
  end

  # A conversion inside the family keeps the session id, so the provider is what tells.
  it 'drops the event once the inbox moved to another provider under the same session id' do
    conversation = create(:conversation, inbox: inbox, account: inbox.account)
    message = create(:message, conversation: conversation, inbox: inbox, account: inbox.account, source_id: '3EB0LATE', content: 'original')
    channel.update_columns(provider: 'uazapi', provider_config: channel.provider_config.merge('base_url' => 'https://uazapi.test', 'token' => 'x')) # rubocop:disable Rails/SkipsModelValidations

    described_class.perform_now(channel, edit.to_frame)

    expect(message.reload.content).to eq('original')
  end

  it 'tries again while the message is still missing' do
    expect { described_class.perform_now(channel, edit.to_frame) }.to have_enqueued_job(described_class)
  end
end
