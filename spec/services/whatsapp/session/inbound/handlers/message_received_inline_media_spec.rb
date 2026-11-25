require 'rails_helper'

# A backend whose events run in a job of their own (Uazapi) downloads an inbound message's
# media before the message is stored, so `message_created` already carries the file. The
# connector's backend keeps handing it to MediaFetchJob; message_received_spec covers that.
RSpec.describe Whatsapp::Session::Inbound::Handlers::MessageReceived do
  subject(:dispatch) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) }

  let(:channel) { create(:channel_whatsapp, provider: 'uazapi', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:base) { channel.provider_config['base_url'] }
  let(:file_url) { 'https://free.uazapi.com/files/redacted/3EB0IMG1' }

  let(:model) { Whatsapp::Session::Model }
  let(:sender) { model::Party.new(phone: '5541999990000', push_name: 'Ana Souza') }
  let(:content) do
    model::Content::Media.new(kind: 'image', mime: 'image/jpeg', caption: 'olha isso',
                              ref: model::MediaRef.new(kind: 'uazapi_message', id: '3EB0IMG1', mime: 'image/jpeg'))
  end
  let(:inbound) do
    model::InboundMessage.new(id: '3EB0IMG1', chat: model::Address.phone('5541999990000'), sender: sender, from_me: false,
                              timestamp: 1_755_440_000_123, content: content)
  end
  let(:event) { model::Event.build(model::Events::MessageReceived.new(message: inbound), epoch: 1, seq: 1) }

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('uazapi.test').and_return(['93.184.216.34'])
    allow(Resolv).to receive(:getaddresses).with('free.uazapi.com').and_return(['93.184.216.34'])
    stub_request(:post, "#{base}/message/markread").to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    stub_request(:post, "#{base}/message/download").to_return(
      status: 200, body: { fileURL: file_url, mimetype: 'image/jpeg' }.to_json, headers: { 'Content-Type' => 'application/json' }
    )
    stub_request(:get, file_url).to_return(status: 200, body: 'jpeg-bytes', headers: { 'Content-Type' => 'image/jpeg' })
  end

  it 'stores the message with its file, so message_created already carries it' do
    attachments_when_created = nil
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, name, *args, **kwargs|
      attachments_when_created = kwargs[:message]&.attachments&.map(&:file_type) if name == Events::Types::MESSAGE_CREATED
      original.call(name, *args, **kwargs)
    end

    expect(dispatch).to eq(:handled)

    message = inbox.messages.find_by(source_id: '3EB0IMG1')
    expect(attachments_when_created).to eq(['image'])
    expect(message.attachments.sole.file.download).to eq('jpeg-bytes')
    expect(Whatsapp::Session::MediaFetchJob).not_to have_been_enqueued
  end

  it 'marks a voice note as recorded audio' do
    content = model::Content::Media.new(kind: 'audio', mime: 'audio/ogg', voice_note: true,
                                        ref: model::MediaRef.new(kind: 'uazapi_message', id: '3EB0IMG1', mime: 'audio/ogg'))
    inbound = model::InboundMessage.new(id: '3EB0IMG1', chat: model::Address.phone('5541999990000'), sender: sender,
                                        from_me: false, timestamp: 1_755_440_000_123, content: content)

    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(model::Events::MessageReceived.new(message: inbound), epoch: 1, seq: 1)
    )

    expect(inbox.messages.find_by(source_id: '3EB0IMG1').attachments.sole.meta).to eq('is_recorded_audio' => true)
  end

  it 'stores the message without the file and leaves it to the fetch job when the download fails' do
    stub_request(:post, "#{base}/message/download").to_return(status: 500, body: '{}', headers: { 'Content-Type' => 'application/json' })

    expect(dispatch).to eq(:handled)

    message = inbox.messages.find_by(source_id: '3EB0IMG1')
    expect(message.content).to eq('olha isso')
    expect(message.attachments).to be_empty
    expect(Whatsapp::Session::MediaFetchJob).to have_been_enqueued.with(message, hash_including('kind' => 'image'), anything)
  end

  # The message and chat locks it runs under last 30 seconds: a download that outlived them
  # would let a redelivery of the same message in beside it.
  it 'stops waiting on a download that does not answer in time' do
    stub_const('Whatsapp::Session::Inbound::MediaAttachment::INLINE_TIMEOUT', 0.1)
    stub_request(:post, "#{base}/message/download").to_return do
      sleep 1
      { status: 200, body: { fileURL: file_url, mimetype: 'image/jpeg' }.to_json, headers: { 'Content-Type' => 'application/json' } }
    end

    expect(dispatch).to eq(:handled)

    message = inbox.messages.find_by(source_id: '3EB0IMG1')
    expect(message.attachments).to be_empty
    expect(Whatsapp::Session::MediaFetchJob).to have_been_enqueued.with(message, hash_including('kind' => 'image'), anything)
  end

  # The file did not come with the message: `media.download_failed` is what says whether it
  # is reachable at all, so nothing is asked for yet.
  it 'asks nothing for media whose bytes did not come with it' do
    content = model::Content::Media.new(kind: 'image', mime: 'image/jpeg', caption: 'olha isso')
    inbound = model::InboundMessage.new(id: '3EB0IMG1', chat: model::Address.phone('5541999990000'), sender: sender,
                                        from_me: false, timestamp: 1_755_440_000_123, content: content)

    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(model::Events::MessageReceived.new(message: inbound), epoch: 1, seq: 1)
    )

    expect(inbox.messages.find_by(source_id: '3EB0IMG1').attachments).to be_empty
    expect(WebMock).not_to have_requested(:post, "#{base}/message/download")
  end

  # A history batch is hundreds of messages under one chat lease: downloading each inline
  # would hold the chat for the whole batch's worth of files. A fetch job of its own would
  # skip the inbox's switch and window, so the file waits for the drain, with the reference
  # the provider finds it by.
  it 'leaves an imported message to the inbox drain' do
    conversation = create(:conversation, inbox: inbox, account: inbox.account)

    message = Whatsapp::Session::Inbound::MessageWriter.new(conversation: conversation, inbound: inbound, imported: true).perform

    expect(message.attachments).to be_empty
    expect(WebMock).not_to have_requested(:post, "#{base}/message/download")
    expect(Whatsapp::Session::MediaFetchJob).not_to have_been_enqueued
    expect(Whatsapp::Session::HistoryMedia.pending?(message.reload)).to be(true)
    expect(message.content_attributes.dig('pending_media', 'ref', 'id')).to eq('3EB0IMG1')
  end
end
