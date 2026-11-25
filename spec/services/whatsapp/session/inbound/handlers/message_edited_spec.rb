require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::MessageEdited do
  subject(:dispatch) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) }

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:conversation) { create(:conversation, inbox: inbox, account: channel.account) }
  let(:message) do
    create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                     content: 'oi', source_id: '3EB0AAAA0001')
  end
  let(:event) do
    model::Event.build(
      model::Events::MessageEdited.new(
        chat: model::Address.phone('5541999990000'), message_id: message.source_id,
        content: model::Content::Text.new(body: 'oi, corrigido')
      )
    )
  end

  it 'replaces the content and keeps the original' do
    expect(dispatch).to eq(:handled)

    expect(message.reload.content).to eq('oi, corrigido')
    expect(message.is_edited).to be(true)
    expect(message.previous_content).to eq('oi')
  end

  # Two edits of one message, delivered the wrong way round. The provider's own clock is
  # what orders them, since arrival is the thing that is out of order.
  it 'refuses an edit older than the one already applied' do
    newer = model::Events::MessageEdited.new(
      chat: model::Address.phone('5541999990000'), message_id: message.source_id,
      content: model::Content::Text.new(body: 'a segunda'), timestamp: 1_755_440_002_000
    )
    older = newer.with(content: model::Content::Text.new(body: 'a primeira'), timestamp: 1_755_440_001_000)

    expect(described_class.new(channel: channel, event: model::Event.build(newer)).perform).to eq(:handled)
    expect(described_class.new(channel: channel, event: model::Event.build(older)).perform).to eq(:ignored)

    expect(message.reload.content).to eq('a segunda')
  end

  # Nobody edits a message they have deleted for everyone, so this only happens when the
  # two arrive out of order. Applying it would put the text back on a bubble WhatsApp has
  # already taken off the contact's phone.
  it 'refuses an edit for a message that was revoked' do
    message.update!(content_attributes: message.content_attributes.merge('deleted' => true))

    expect(dispatch).to eq(:ignored)
    expect(message.reload.is_edited).to be_nil
  end

  # The connector publishes a correction whose new body it cannot render with the
  # unsupported placeholder rather than holding it back (PROTOCOL.md, connector #402). It
  # says the message was corrected into something nobody here can show, not what it says
  # now, so the readable body the bubble has stays.
  %w[unknown_type empty].each do |reason|
    it "keeps the bubble it has for an edit published as unsupported (#{reason})" do
      unsupported = event.payload.with(content: model::Content::Unsupported.new(reason: reason))

      expect(described_class.new(channel: channel, event: model::Event.build(unsupported)).perform).to eq(:ignored)

      expect(message.reload.content).to eq('oi')
      expect(message.is_edited).to be_nil
    end
  end

  it 'refuses an edit for a message the contact revoked' do
    message.update!(content_attributes: message.content_attributes.merge('deleted_by_contact' => true))

    expect(dispatch).to eq(:ignored)
    expect(message.reload.content).to eq('oi')
  end

  # An edit is the first readable body a placeholder's row has had, so leaving the flag on
  # renders the edit as the unsupported bubble, which shows none of it. The recovery
  # marker stays: the row has a body now and is still missing what the message carried
  # around it, which only the delayed recovery has.
  it 'stops calling a placeholder unreadable once the edit gives it a body' do
    message.update!(content: nil, content_attributes: { 'is_unsupported' => true,
                                                        'unsupported_reason' => 'undecryptable' })

    expect(dispatch).to eq(:handled)

    expect(message.reload.content).to eq('oi, corrigido')
    expect(message.content_attributes).not_to have_key('is_unsupported')
    expect(message.content_attributes['unsupported_reason']).to eq('undecryptable')
  end

  # `is_unsupported` also marks media that never arrived, and a new caption is no answer
  # to bytes that are not coming: the bubble has to go on saying the attachment is not
  # coming, or the agent is left waiting for one.
  it 'leaves a media failure saying the attachment is not coming' do
    message.update_under_lock!(is_unsupported: true)

    expect(dispatch).to eq(:handled)

    expect(message.reload.content).to eq('oi, corrigido')
    expect(message.is_unsupported).to be(true)
  end

  it 'keeps the first version across a second edit' do
    dispatch
    described_class.new(
      channel: channel,
      event: model::Event.build(
        model::Events::MessageEdited.new(
          chat: model::Address.phone('5541999990000'), message_id: message.source_id,
          content: model::Content::Text.new(body: 'terceira versão')
        )
      )
    ).perform

    expect(message.reload.previous_content).to eq('oi')
    expect(message.content).to eq('terceira versão')
  end

  it 'waits for a message it has not stored yet' do
    event = model::Event.build(
      model::Events::MessageEdited.new(chat: model::Address.phone('5541999990000'), message_id: '3EB0UNKNOWN',
                                       content: model::Content::Text.new(body: 'x'))
    )

    expect(described_class.new(channel: channel, event: event).perform).to eq(:deferred)
  end

  # Removing a caption is a real edit, and dropping it left the old caption on screen
  # with no way to clear it.
  context 'when the edit clears a media caption' do
    let(:event) do
      model::Event.build(
        model::Events::MessageEdited.new(
          chat: model::Address.phone('5541999990000'), message_id: message.source_id,
          content: model::Content::Media.new(kind: 'image', mime: 'image/jpeg', caption: '')
        )
      )
    end

    it 'clears the stored caption' do
      expect(dispatch).to eq(:handled)
      expect(message.reload.content).to eq('')
    end
  end
end
