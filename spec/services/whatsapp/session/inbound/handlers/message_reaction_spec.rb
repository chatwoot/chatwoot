require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::MessageReaction do
  subject(:dispatch) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) }

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:contact) { create(:contact, account: channel.account, phone_number: '+5541999990000', identifier: '182736451928374@lid') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: '182736451928374') }
  let(:conversation) { create(:conversation, contact: contact, contact_inbox: contact_inbox, inbox: inbox, account: channel.account) }
  let(:target) do
    create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                     message_type: :outgoing, source_id: '3EB0TARGET')
  end
  let(:sender) { model::Party.new(phone: '5541999990000', lid: '182736451928374', push_name: 'Ana Souza') }
  let(:emoji) { '👍' }
  let(:reaction) do
    model::Events::MessageReaction.new(
      id: '3EB0REACTION', chat: model::Address.phone('5541999990000'), sender: sender,
      from_me: false, target_id: target.source_id, emoji: emoji, timestamp: 1_755_440_000_123
    )
  end
  let(:event) { model::Event.build(reaction) }

  it 'stores the reaction in the thread of the message it annotates' do
    expect(dispatch).to eq(:handled)

    stored = inbox.messages.find_by(source_id: '3EB0REACTION')
    expect(stored.content).to eq('👍')
    expect(stored.conversation).to eq(conversation)
    expect(stored.content_attributes['is_reaction']).to be(true)
    expect(stored.content_attributes['in_reply_to_external_id']).to eq('3EB0TARGET')
  end

  # WhatsApp gives a changed reaction a new id, so swapping one emoji for another is a
  # fresh event, not an edit. A second row would show both emojis on the bubble and
  # leave one behind when the reaction is taken back.
  it 'replaces a reaction the same sender already left' do
    target
    dispatch

    changed = model::Events::MessageReaction.new(
      id: '3EB0REACTION2', chat: model::Address.phone('5541999990000'), sender: sender,
      from_me: false, target_id: target.source_id, emoji: '❤️', timestamp: 1_755_440_000_456
    )
    Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, model::Event.build(changed))

    rows = conversation.messages.where("(content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true'")
    expect(rows.count).to eq(1)
    expect(rows.first).to have_attributes(content: '❤️', source_id: '3EB0REACTION2')
  end

  # The reaction Chatwoot sent reserved its id, and a lost send response makes the echo
  # arrive under an id we never stored.
  context 'with the echo of a reaction Chatwoot sent' do
    let(:reaction) do
      model::Events::MessageReaction.new(
        id: '3EB0RESERVED', chat: model::Address.phone('5541999990000'), sender: nil,
        from_me: true, target_id: target.source_id, emoji: emoji, timestamp: 1_755_440_000_123
      )
    end

    it 'confirms the reserved row instead of adding a second reaction' do
      reserved = create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                                  message_type: :outgoing, source_id: nil,
                                  content_attributes: { is_reaction: true, pending_source_id: '3EB0RESERVED' })

      expect(dispatch).to eq(:handled)

      expect(reserved.reload.source_id).to eq('3EB0RESERVED')
      expect(conversation.messages.where("(content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true'").count).to eq(1)
    end
  end

  # The provider that assigns its own message id gives the echo one we never stored, and
  # its reaction echo carries no correlation token either, so neither the id nor the
  # reservation can recognize it. What is left is the target: on the WhatsApp side a
  # `from_me` reaction has one author, the connected number, whether the agent wrote it
  # here or somebody wrote it on the phone. Read as two authors it becomes a second emoji
  # on the bubble that no removal can take back.
  context 'with the echo of an agent reaction the provider named itself' do
    let(:agent) { create(:user, account: channel.account) }
    let(:reaction) do
      model::Events::MessageReaction.new(
        id: '5511999990001:3EB0PROVIDER', chat: model::Address.phone('5541999990000'), sender: nil,
        from_me: true, target_id: target.source_id, emoji: emoji, timestamp: 1_755_440_000_123
      )
    end

    it 'lands on the row the agent already has instead of adding a second one' do
      agent_row = create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                                   message_type: :outgoing, sender: agent, source_id: nil, content: emoji,
                                   content_attributes: { is_reaction: true, in_reply_to_external_id: target.source_id,
                                                         pending_source_id: '3EB0RESERVED' })

      expect(dispatch).to eq(:handled)

      expect(conversation.messages.where("(content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true'").count).to eq(1)
      expect(agent_row.reload.source_id).to eq('5511999990001:3EB0PROVIDER')
    end
  end

  # Two agents can each hold an outgoing reaction on one target, since a row is filed per
  # user here where WhatsApp keeps one reaction per number. Landing the echo on the newest
  # would leave the row that actually sent it without an id, and its retry would send a
  # second time.
  context 'with two agents holding a reaction on the same message' do
    let(:agent) { create(:user, account: channel.account) }
    let(:other) { create(:user, account: channel.account) }
    let(:reaction) do
      model::Events::MessageReaction.new(
        id: '5511999990001:3EB0PROVIDER', chat: model::Address.phone('5541999990000'), sender: nil,
        from_me: true, target_id: target.source_id, emoji: '👍', timestamp: 1_755_440_000_123
      )
    end

    it 'confirms the one still waiting for an id that asked for this emoji' do
      sending = create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                                 message_type: :outgoing, sender: agent, source_id: nil, content: '👍',
                                 content_attributes: { is_reaction: true, in_reply_to_external_id: target.source_id,
                                                       pending_source_id: '3EB0RESERVED' })
      settled = create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                                 message_type: :outgoing, sender: other, source_id: '3EB0SETTLED', content: '❤️',
                                 content_attributes: { is_reaction: true, in_reply_to_external_id: target.source_id })

      expect(dispatch).to eq(:handled)

      expect(sending.reload.source_id).to eq('5511999990001:3EB0PROVIDER')
      expect(settled.reload.source_id).to eq('3EB0SETTLED')
    end
  end

  # Resolving a sender creates a Contact, a ContactInbox and an avatar job, and a
  # removal aimed at a message nobody reacted to has nothing to remove.
  context 'with a removal that matches nothing' do
    let(:emoji) { '' }
    let(:reaction) do
      model::Events::MessageReaction.new(
        id: '3EB0REMOVE', chat: model::Address.phone('5541900001111'),
        sender: model::Party.new(phone: '5541900001111'), from_me: false,
        target_id: '3EB0UNKNOWN', emoji: '', timestamp: 1_755_440_000_123
      )
    end

    # Deferred rather than dropped, and still without resolving anybody: nothing recorded
    # for this sender is also what a removal that overtook its own reaction looks like,
    # and this transport cannot tell the two apart. The job waits, and a removal that
    # really is aimed at nothing is dropped once the retries are spent.
    it 'waits for the reaction it takes back, leaving no contact behind' do
      expect { expect(dispatch).to eq(:deferred) }.not_to change(Contact, :count)
    end
  end

  # A swap arriving the wrong way round: the emoji the sender moved away from must not
  # land back on the bubble.
  it 'refuses a reaction older than the one already on the bubble' do
    newer = model::Events::MessageReaction.new(
      id: '3EB0SWAP2', chat: model::Address.phone('5541999990000'), sender: sender, from_me: false,
      target_id: target.source_id, emoji: '❤️', timestamp: 1_755_440_002_000
    )
    older = newer.with(id: '3EB0SWAP1', emoji: '👍', timestamp: 1_755_440_001_000)

    expect(described_class.new(channel: channel, event: model::Event.build(newer)).perform).to eq(:handled)
    expect(described_class.new(channel: channel, event: model::Event.build(older)).perform).to eq(:ignored)

    stored = inbox.messages.find_by("(content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true'")
    expect(stored.content).to eq('❤️')
  end

  # Replayed off the ordered stream, a reaction can run after the removal that followed it
  # on the phone; the removal is where the phone ended.
  it 'refuses a reaction older than a removal already applied' do
    target
    create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                     message_type: :incoming, sender: contact, content: '',
                     content_attributes: { is_reaction: true, in_reply_to_external_id: '3EB0TARGET', deleted: true,
                                           external_created_at: 1_755_440_100 })

    expect(dispatch).to eq(:ignored)

    expect(inbox.messages.where("(content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true'").where.not(content: '')).to be_empty
  end

  # add A, remove, add B, remove, replayed as A, remove, remove, B: the second removal
  # finds nothing active and still has to count, or B comes back.
  it 'keeps a reaction removed however its toggles are replayed' do
    target
    toggle = lambda do |id, emoji, second|
      event = model::Event.build(reaction.with(id: id, emoji: emoji, timestamp: (1_755_440_000 + second) * 1000))
      described_class.new(channel: channel, event: event).perform
    end

    toggle.call('3EB0A', '👍', 1)
    toggle.call('3EB0R1', nil, 2)
    toggle.call('3EB0R2', nil, 4)
    toggle.call('3EB0B', '❤️', 3)

    active = inbox.messages.where("(content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true'").where.not(content: '')
    expect(active).to be_empty
  end

  # The removal dates the tombstone it leaves, so a reaction older than the removal but
  # newer than what was removed is still refused when it is replayed afterwards.
  it 'refuses a reaction replayed after a removal that came later on the phone' do
    target
    toggle = lambda do |id, emoji, second|
      event = model::Event.build(reaction.with(id: id, emoji: emoji, timestamp: (1_755_440_000 + second) * 1000))
      described_class.new(channel: channel, event: event).perform
    end

    toggle.call('3EB0A', '👍', 1)
    toggle.call('3EB0R', nil, 3)

    expect(toggle.call('3EB0B', '❤️', 2)).to eq(:ignored)
  end

  context 'when the contact takes the reaction back' do
    let(:emoji) { nil }

    before do
      target
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       message_type: :incoming, sender: contact, content: '👍',
                       content_attributes: { is_reaction: true, in_reply_to_external_id: '3EB0TARGET' })
    end

    it 'empties the stored reaction instead of creating a row' do
      expect(dispatch).to eq(:handled)

      removed = inbox.messages.find_by("(content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true'")
      expect(removed.content).to eq('')
      expect(removed.content_attributes['deleted']).to be(true)
    end

    # Replayed late, off the ordered stream, after the sender reacted again: the removal
    # is about the reaction before, and the one on the bubble now stays.
    it 'leaves a newer reaction alone when the removal is older than it' do
      inbox.messages.where("(content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true'").find_each do |row|
        row.update!(content: '❤️', content_attributes: row.content_attributes.merge('external_created_at' => 1_755_440_100))
      end

      expect(dispatch).to eq(:ignored)

      kept = inbox.messages.find_by("(content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true'")
      expect(kept.content).to eq('❤️')
      expect(kept.content_attributes['deleted']).to be_nil
    end

    it 'ignores a removal with nothing left to remove' do
      inbox.messages.where("(content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true'")
           .update_all(content: '') # rubocop:disable Rails/SkipsModelValidations

      expect(dispatch).to eq(:ignored)
    end
  end

  # Resolving the peer creates a Contact, a ContactInbox and an avatar job, and a
  # reaction whose target was never stored has nothing to annotate: it used to open a
  # thread of its own to hold a reaction pointing at a message that does not exist.
  # Scoped to the target alone, somebody else's reaction answered yes and the removal
  # resolved a contact on its way to doing nothing, which is the exact leak the guard
  # exists to stop.
  context 'when the removal comes from somebody who never reacted' do
    let(:emoji) { nil }
    let(:reaction) do
      model::Events::MessageReaction.new(
        id: '3EB0REMOVE2', chat: model::Address.phone('5541900002222'),
        sender: model::Party.new(phone: '5541900002222'), from_me: false,
        target_id: target.source_id, emoji: '', timestamp: 1_755_440_000_123
      )
    end

    before do
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       message_type: :incoming, sender: contact, content: '👍',
                       content_attributes: { is_reaction: true, in_reply_to_external_id: '3EB0TARGET' })
    end

    it 'leaves no contact behind' do
      expect { expect(dispatch).to eq(:deferred) }.not_to change(Contact, :count)
    end
  end

  context 'when the message it reacts to was never stored' do
    let(:reaction) do
      model::Events::MessageReaction.new(
        id: '3EB0REACTION', chat: model::Address.phone('5541999990000'), sender: sender,
        from_me: false, target_id: '3EB0NEVERSEEN', emoji: emoji, timestamp: 1_755_440_000_123
      )
    end

    it 'waits for it instead of inventing a contact and a thread' do
      expect { expect(dispatch).to eq(:deferred) }
        .to not_change(Contact, :count).and not_change(inbox.conversations, :count)
    end
  end

  context 'when the reaction was made on the connected phone' do
    let(:emoji) { nil }
    let(:reaction) do
      model::Events::MessageReaction.new(
        id: '3EB0REACTION', chat: model::Address.phone('5541999990000'), sender: nil,
        from_me: true, target_id: target.source_id, emoji: nil, timestamp: 1_755_440_000_123
      )
    end

    before do
      target
      # :bot_message is the factory trait for an outgoing message with no agent behind it,
      # which is how a reaction made on the connected phone is stored.
      create(:message, :bot_message, conversation: conversation, inbox: inbox, account: channel.account,
                                     content: '👍', content_attributes: { is_reaction: true, in_reply_to_external_id: '3EB0TARGET' })
    end

    it 'removes the agent-less reaction row' do
      expect(dispatch).to eq(:handled)

      removed = inbox.messages.where(message_type: :outgoing)
                     .find_by("(content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true'")
      expect(removed.content_attributes['deleted']).to be(true)
    end
  end
end
