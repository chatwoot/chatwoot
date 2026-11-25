require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::MessageReceipt do
  subject(:dispatch) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) }

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:conversation) { create(:conversation, inbox: inbox, account: channel.account) }
  let(:message) do
    create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                     message_type: :outgoing, status: :sent, source_id: '3EB0AAAA0001')
  end
  let(:receipt) do
    model::Events::MessageReceipt.new(chat: model::Address.phone('5541999990000'),
                                      message_ids: [message.source_id], type: type)
  end
  let(:type) { 'delivered' }
  let(:event) { model::Event.build(receipt) }

  it 'moves the message forward' do
    expect(dispatch).to eq(:handled)
    expect(message.reload.status).to eq('delivered')
  end

  context 'when the id covers every card of a shared-contact message' do
    let!(:second_card) do
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       message_type: :outgoing, status: :sent, source_id: message.source_id)
    end

    it 'moves all of them forward' do
      expect(dispatch).to eq(:handled)

      expect(message.reload.status).to eq('delivered')
      expect(second_card.reload.status).to eq('delivered')
    end
  end

  # A receipt is a batch by nature and a large one by habit: opening a chat produced one
  # read event naming 246 messages, most of them from before the inbox existed. A lookup
  # per id put hundreds of round trips on the queue inbound messages share.
  context 'with a receipt naming many messages' do
    let(:receipt) do
      model::Events::MessageReceipt.new(chat: model::Address.phone('5541999990000'),
                                        message_ids: [message.source_id] + Array.new(40) { |n| "3EB0BEFORE#{n}" },
                                        type: type)
    end

    it 'looks them up in one query' do
      message
      lookups = 0
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        lookups += 1 if payload[:sql].include?('"messages"') && payload[:sql].include?('"source_id"')
      end

      expect(dispatch).to eq(:handled)

      ActiveSupport::Notifications.unsubscribe(subscriber)
      expect(lookups).to eq(1)
    end
  end

  # The race that motivates the locked write is covered where it happens, in the
  # StatusTransition unit; this only checks the failure reaches the row it names.
  context 'when the send failed for a message already deleted' do
    let(:type) { 'failed' }
    let(:receipt) do
      model::Events::MessageReceipt.new(chat: model::Address.phone('5541999990000'),
                                        message_ids: [message.source_id], type: 'failed',
                                        error: 'recipient unreachable')
    end

    before do
      message
      Message.find(message.id).update!(content_attributes: { 'deleted' => true })
    end

    it 'records the error without undeleting the message' do
      expect(dispatch).to eq(:handled)

      expect(message.reload).to have_attributes(status: 'failed', external_error: 'recipient unreachable')
      expect(message.content_attributes['deleted']).to be(true)
    end
  end

  # Unread counts compare a message's creation time against these markers, so stamping
  # the clock marks every incoming message that arrived since as seen: a receipt for an
  # older message, delivered late, cleared the badge for messages nobody here opened.
  context 'when a read receipt for an older message arrives after a newer one' do
    let(:type) { 'read' }
    let(:receipt) do
      model::Events::MessageReceipt.new(chat: model::Address.phone('5541999990000'),
                                        message_ids: [old_incoming.source_id], type: 'read',
                                        timestamp: 1.hour.ago.to_i * 1000)
    end
    let!(:old_incoming) do
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       message_type: :incoming, source_id: '3EB0OLD0001', created_at: 2.hours.ago)
    end
    let!(:newer_incoming) do
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       message_type: :incoming, source_id: '3EB0NEW0001')
    end

    it 'does not mark the newer message as seen' do
      conversation.update_columns(agent_last_seen_at: nil) # rubocop:disable Rails/SkipsModelValidations

      dispatch

      expect(conversation.reload.agent_last_seen_at).to be < newer_incoming.created_at
    end
  end

  context 'when the contact read it' do
    let(:type) { 'read' }

    it 'marks the message read' do
      expect(dispatch).to eq(:handled)
      expect(message.reload.status).to eq('read')
    end

    # The contact reading us says nothing about what we have seen. Treating it as a
    # read on our side would clear the unread badge for incoming messages that arrived
    # before the receipt and that nobody here has opened.
    it 'leaves the unread badge alone' do
      conversation.update_columns(agent_last_seen_at: 1.hour.ago) # rubocop:disable Rails/SkipsModelValidations
      incoming = create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                                  message_type: :incoming)

      expect { dispatch }.not_to(change { conversation.reload.agent_last_seen_at })
      expect(conversation.reload.unread_incoming_messages).to include(incoming)
    end
  end

  context 'when one of our own devices marked the chat read' do
    let(:type) { 'read' }
    let(:message) do
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       message_type: :incoming, status: :sent, source_id: '3EB0AAAA0002')
    end

    it 'marks the thread seen' do
      expect(dispatch).to eq(:handled)
      expect(conversation.reload.agent_last_seen_at).to be_present
    end

    it 'still advances the timestamps when the status has nowhere left to go' do
      message.update!(status: :read)
      conversation.update_columns(agent_last_seen_at: 1.hour.ago) # rubocop:disable Rails/SkipsModelValidations

      expect { dispatch }.to(change { conversation.reload.agent_last_seen_at })
    end
  end

  # Uazapi answers our own `/message/markread` with a `read` webhook naming the messages we
  # just acknowledged. Taken for a device of this account, it would clear the unread badge of
  # a conversation an agent bot read on the provider only and no human has opened.
  context 'when the receipt is this app echoed back' do
    let(:type) { 'read' }
    let(:message) do
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       message_type: :incoming, status: :sent, source_id: '3EB0AAAA0003')
    end

    before { Whatsapp::SelfReadReceipts.record(conversation, [message]) }

    after { Redis::Alfred.delete(Whatsapp::SelfReadReceipts.key(conversation, message.source_id)) }

    it 'leaves the unread markers alone' do
      conversation.update_columns(agent_last_seen_at: nil) # rubocop:disable Rails/SkipsModelValidations

      dispatch

      expect(conversation.reload.agent_last_seen_at).to be_nil
    end

    it 'still marks the message read' do
      expect(dispatch).to eq(:handled)
      expect(message.reload.status).to eq('read')
    end

    # One `source_id` can name several rows -- a shared-contact payload stores a card each
    # -- and the handler applies the receipt to all of them. A marker on the row the sender
    # happened to name would let a sibling clear the badge anyway.
    it 'covers every card the id resolves to' do
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       message_type: :incoming, status: :sent, source_id: message.source_id)
      conversation.update_columns(agent_last_seen_at: nil) # rubocop:disable Rails/SkipsModelValidations

      dispatch

      expect(conversation.reload.agent_last_seen_at).to be_nil
    end

    # The marker answers for the ids this app acknowledged and for nothing else. Anchored to
    # the conversation instead, it would swallow every later read the paired phone reports,
    # and each new bot receipt would push that window out again.
    # The handler resolves a whole receipt in one query on purpose; asking Redis per message
    # would put a round trip back per id, which is hundreds on a receipt naming a whole chat.
    it 'reads the acknowledged ids once for the whole batch' do
      allow(Whatsapp::SelfReadReceipts).to receive(:acknowledged).and_call_original
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       message_type: :incoming, status: :sent, source_id: message.source_id)

      dispatch

      expect(Whatsapp::SelfReadReceipts).to have_received(:acknowledged).once
    end

    it 'lets a device read of another message in the chat through' do
      other = create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                               message_type: :incoming, status: :sent, source_id: '3EB0AAAA0004')
      conversation.update_columns(agent_last_seen_at: nil) # rubocop:disable Rails/SkipsModelValidations

      Whatsapp::Session::Inbound::Dispatcher.dispatch(
        channel,
        model::Event.build(
          model::Events::MessageReceipt.new(chat: model::Address.phone('5541999990000'),
                                            message_ids: [other.source_id], type: 'read')
        )
      )

      expect(conversation.reload.agent_last_seen_at).to be_present
    end
  end

  context 'when a weaker receipt arrives late' do
    let(:type) { 'delivered' }

    before { message.update!(status: :read) }

    it 'keeps the stronger status' do
      expect(dispatch).to eq(:ignored)
      expect(message.reload.status).to eq('read')
    end
  end

  context 'when the message is not stored' do
    let(:receipt) do
      model::Events::MessageReceipt.new(chat: model::Address.phone('5541999990000'),
                                        message_ids: ['3EB0UNKNOWN'], type: 'delivered')
    end

    it 'ignores the receipt' do
      expect(dispatch).to eq(:ignored)
    end
  end

  context 'when the provider reports a failure' do
    let(:type) { 'failed' }
    let(:receipt) do
      model::Events::MessageReceipt.new(
        chat: model::Address.phone('5541999990000'), message_ids: [message.source_id], type: 'failed',
        error: model::WireError.new(code: 'recipient_not_on_whatsapp', message: 'not on whatsapp')
      )
    end

    it 'fails the message and keeps the provider reason' do
      expect(dispatch).to eq(:handled)
      expect(message.reload.status).to eq('failed')
      expect(message.external_error).to include('not on whatsapp')
    end
  end
end
