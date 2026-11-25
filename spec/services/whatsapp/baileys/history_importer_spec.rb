require 'rails_helper'

describe Whatsapp::Baileys::HistoryImporter do
  let!(:whatsapp_channel) do
    create(:channel_whatsapp,
           provider: 'baileys',
           provider_config: { webhook_verify_token: 'valid_token' },
           validate_provider_config: false,
           received_messages: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:phone) { '5511912345678' }
  let(:lid) { '12345678' }
  let(:jid) { "#{lid}@lid" }

  def raw_message(id, sent_at:, body: "message #{id}", from_me: false, message: nil)
    {
      key: { id: id, remoteJid: jid, remoteJidAlt: "#{phone}@s.whatsapp.net", fromMe: from_me, addressingMode: 'lid' },
      pushName: 'June',
      messageTimestamp: sent_at.to_i,
      message: message || { conversation: body }
    }.with_indifferent_access
  end

  def import(messages, watermark: nil, requested: true, group_name: nil)
    described_class.new(
      inbox: inbox,
      params: { messages: messages, watermark: watermark, requested: requested, group_name: group_name }
    ).perform
  end

  # Two seconds, not one: the provider clocks a message in whole seconds, so a date that
  # made the round trip through `messageTimestamp` has already lost its fraction before
  # anything here compares it against a freshly evaluated `N.days.ago`.
  before { stub_request(:get, /profile-picture-url/).to_return(status: 200, body: { data: { profilePictureUrl: nil } }.to_json) }

  describe 'the coverage split' do
    let(:watermark) { 3.days.ago }

    # Nobody has had the chance to read it, so it is late mail and belongs in the queue.
    it 'files a message newer than the boundary as open work' do
      import([raw_message('GAP', sent_at: 1.day.ago)], watermark: watermark)

      message = inbox.messages.find_by(source_id: 'GAP')
      expect(message.conversation).not_to be_resolved
      expect(message.created_at).to be_within(2.seconds).of(1.day.ago)
    end

    # Filed resolved from the start rather than resolved afterwards: a thread born in that
    # state fires no resolution reporting event and writes no "resolved by" line.
    it 'files a message older than the boundary as archive' do
      import([raw_message('OLD', sent_at: 10.days.ago)], watermark: watermark)

      message = inbox.messages.find_by(source_id: 'OLD')
      expect(message.conversation).to be_resolved
      expect(message.created_at).to be_within(2.seconds).of(10.days.ago)
    end

    it 'keeps the two halves in different threads' do
      import([raw_message('OLD', sent_at: 10.days.ago), raw_message('GAP', sent_at: 1.day.ago)], watermark: watermark)

      old = inbox.messages.find_by(source_id: 'OLD')
      gap = inbox.messages.find_by(source_id: 'GAP')
      expect(old.conversation_id).not_to eq(gap.conversation_id)
      expect(old.conversation).to be_resolved
      expect(gap.conversation).not_to be_resolved
    end

    # A first pairing has no coverage at all, so the whole pile is archive. With nobody
    # having asked, that means nothing is written: the privacy protection the outright
    # refusal used to provide.
    # By date, not into the newest thread: the dashboard walks a contact's threads in the
    # order they were opened, so each message goes to the one that was current then.
    it 'files each archived message in the thread that was current when it was sent' do
      import([raw_message('FIRST', sent_at: 20.days.ago)], watermark: watermark)
      first = inbox.messages.find_by(source_id: 'FIRST').conversation
      later = create(:conversation, inbox: inbox, account: inbox.account, contact: first.contact,
                                    contact_inbox: first.contact_inbox, created_at: 5.days.ago)

      import([raw_message('BEFORE', sent_at: 10.days.ago), raw_message('AFTER', sent_at: 4.days.ago)], watermark: 1.day.ago)

      expect(inbox.messages.find_by(source_id: 'BEFORE').conversation).to eq(first)
      expect(inbox.messages.find_by(source_id: 'AFTER').conversation).to eq(later)
    end

    # Filed by its own date the reaction would go to the later thread, where nothing finds
    # the message it annotates and the thread never shows it.
    it 'files an archived reaction with the message it reacts to' do
      import([raw_message('FIRST', sent_at: 20.days.ago)], watermark: watermark)
      first = inbox.messages.find_by(source_id: 'FIRST').conversation
      create(:conversation, inbox: inbox, account: inbox.account, contact: first.contact, contact_inbox: first.contact_inbox,
                            created_at: 5.days.ago)
      reaction = { reactionMessage: { key: { id: 'TARGET', remoteJid: jid, fromMe: false }, text: '👍' } }

      import([raw_message('TARGET', sent_at: 10.days.ago), raw_message('LIKE', sent_at: 4.days.ago, message: reaction)],
             watermark: 1.day.ago)

      expect(inbox.messages.find_by(source_id: 'LIKE').conversation).to eq(first)
    end

    it 'writes nothing from a pile nobody asked for' do
      import([raw_message('OLD', sent_at: 10.days.ago)], watermark: nil, requested: false)

      expect(inbox.messages).to be_empty
    end

    # What arrived while the session was down is a different thing from an archive, and it
    # is the only part of an unprompted offer this inbox is missing.
    it 'keeps the gap of a pile nobody asked for' do
      import([raw_message('OLD', sent_at: 10.days.ago), raw_message('GAP', sent_at: 1.day.ago)],
             watermark: watermark, requested: false)

      expect(inbox.messages.pluck(:source_id)).to contain_exactly('GAP')
    end
  end

  it 'skips a message the inbox already holds' do
    conversation = create(:conversation, inbox: inbox, account: inbox.account)
    create(:message, conversation: conversation, inbox: inbox, source_id: 'A', content: 'stored')

    import([raw_message('A', sent_at: 2.days.ago, body: 'from the dump')], watermark: 3.days.ago)

    expect(inbox.messages.where(source_id: 'A').pluck(:content)).to eq(['stored'])
  end

  # The phone repeats itself inside a single dump.
  it 'writes one row for an id repeated in the same dump' do
    import([raw_message('A', sent_at: 2.days.ago), raw_message('A', sent_at: 2.days.ago)], watermark: 3.days.ago)

    expect(inbox.messages.where(source_id: 'A').count).to eq(1)
  end

  # What a report excluding backfilled traffic reads, and what keeps the coverage boundary
  # from moving under a later frame of the same sync.
  it 'marks the row as filed after the fact' do
    import([raw_message('A', sent_at: 2.days.ago)], watermark: 3.days.ago)

    expect(inbox.messages.find_by(source_id: 'A').content_attributes['imported']).to be(true)
  end

  it 'runs the live pipeline, so an echo is stored the way the live path stores one' do
    import([raw_message('MINE', sent_at: 2.days.ago, from_me: true)], watermark: 3.days.ago)

    message = inbox.messages.find_by(source_id: 'MINE')
    expect(message).to be_outgoing
    expect(message.sender).to be_nil
    expect(message.content_attributes['external_sender_name']).to eq('WhatsApp')
  end

  # The dump carries no media bytes and the bridge never fetched them, so the file the live
  # path downloads was never written. Every media message would be a round trip to a 404.
  it 'stores a media message unsupported without asking the provider for the file' do
    media = { imageMessage: { caption: 'a photo', mimetype: 'image/jpeg' } }
    import([raw_message('IMG', sent_at: 2.days.ago, message: media)], watermark: 3.days.ago)

    message = inbox.messages.find_by(source_id: 'IMG')
    expect(message.content_attributes['is_unsupported']).to be(true)
    expect(message.attachments).to be_empty
    expect(a_request(:get, %r{/media/})).not_to have_been_made
  end

  # The live rule (#793): what a blocked contact sends is not filed, and the echo of a reply
  # typed on the phone is, so the agent's own answer does not go missing.
  describe 'a blocked contact' do
    let!(:contact) { create(:contact, account: inbox.account, name: 'June', phone_number: "+#{phone}", blocked: true) }

    before { create(:contact_inbox, inbox: inbox, contact: contact, source_id: lid) }

    it 'files only the echoes' do
      import([raw_message('IN', sent_at: 2.days.ago), raw_message('OUT', sent_at: 1.day.ago, from_me: true)])

      expect(inbox.messages.pluck(:source_id)).to eq(['OUT'])
    end

    it 'leaves no thread behind when the contact is all the dump has' do
      import([raw_message('IN', sent_at: 2.days.ago)])

      expect(inbox.conversations).to be_empty
    end
  end

  describe 'what an import may set off' do
    it 'never tells WhatsApp the messages were received' do
      channel = create(:channel_whatsapp, provider: 'baileys',
                                          provider_config: { webhook_verify_token: 'valid_token' },
                                          validate_provider_config: false)
      stub_request(:post, %r{/send-receipts}).to_return(status: 200, body: { data: {} }.to_json)

      described_class.new(
        inbox: channel.inbox,
        params: { messages: [raw_message('A', sent_at: 2.days.ago)], watermark: 3.days.ago, requested: true }
      ).perform

      expect(a_request(:post, %r{/send-receipts})).not_to have_been_made
    end

    it 'fires no automation, webhook or notification' do
      expect do
        import([raw_message('A', sent_at: 2.days.ago)], watermark: 3.days.ago)
      end.not_to have_enqueued_job(EventDispatcherJob)
    end
  end

  # A dump carries far more markers than messages, and the records behind a chat are
  # resolved once, before its first row is written. Measured on a real pairing: 519 of the
  # 614 threads it created held nothing at all.
  describe 'a chat the dump carries no message for' do
    let(:stub_message) do
      raw_message('STUB', sent_at: 10.days.ago).tap do |raw|
        raw.delete(:message)
        raw[:messageStubType] = 75
      end
    end

    it 'leaves no empty thread behind' do
      import([stub_message], watermark: 3.days.ago)

      expect(inbox.conversations).to be_empty
    end

    it 'creates no contact for it either' do
      import([stub_message], watermark: 3.days.ago)

      expect(inbox.contact_inboxes).to be_empty
    end

    it 'still files the chat whose dump mixes markers with messages' do
      import([stub_message, raw_message('REAL', sent_at: 10.days.ago)], watermark: 3.days.ago)

      expect(inbox.messages.pluck(:source_id)).to contain_exactly('REAL')
      expect(inbox.conversations.count).to eq(1)
    end
  end

  describe 'the stamps the suppressed callbacks would have kept' do
    it 'sorts the thread by the newest message it imported, not by the import' do
      import([raw_message('A', sent_at: 10.days.ago), raw_message('B', sent_at: 9.days.ago)], watermark: 11.days.ago)

      conversation = inbox.messages.find_by(source_id: 'B').conversation
      expect(conversation.last_activity_at).to be_within(2.seconds).of(9.days.ago)
    end

    # A thread this run opened is born stamped "waiting since now", which is wrong about a
    # message from last week.
    it 'dates the queue clock from the oldest unanswered message' do
      import([raw_message('A', sent_at: 2.days.ago), raw_message('B', sent_at: 1.day.ago)], watermark: 3.days.ago)

      conversation = inbox.messages.find_by(source_id: 'A').conversation
      expect(conversation.waiting_since).to be_within(2.seconds).of(2.days.ago)
    end

    # `handle_resolved_status_change` clears the clock on a thread that *becomes* resolved,
    # and an archive thread is born resolved instead, so nothing ever clears the stamp
    # `ensure_waiting_since` writes at creation. `Conversation.unattended` reads
    # `waiting_since` with no status of its own, so the whole archive would be filed as
    # unattended forever. Measured on a real pairing: 613 of 613 imported threads.
    it 'runs no queue clock on a thread it filed as archive' do
      import([raw_message('OLD', sent_at: 10.days.ago)], watermark: 3.days.ago)

      conversation = inbox.messages.find_by(source_id: 'OLD').conversation
      expect(conversation).to be_resolved
      expect(conversation.waiting_since).to be_nil
    end

    # An archive is filed resolved so it asks for nobody's attention, and a thread nobody
    # has ever opened counts every message as unread, so without this it would arrive
    # resolved and still wearing an unread badge.
    it 'draws no unread badge on a thread it filed as archive' do
      import([raw_message('OLD', sent_at: 10.days.ago)], watermark: 3.days.ago)

      conversation = inbox.messages.find_by(source_id: 'OLD').conversation
      expect(conversation.unread_incoming_messages).to be_empty
    end

    # A dump arrives in frames filed by separate workers, so the thread a later frame adds
    # to was created by a worker this one cannot see. Measured on a real pairing: two
    # threads left with a stamp three minutes behind their own newest row.
    it 'draws no badge on a thread an earlier frame created' do
      import([raw_message('FIRST', sent_at: 10.days.ago)], watermark: 3.days.ago)
      import([raw_message('LATER', sent_at: 9.days.ago)], watermark: 3.days.ago)

      conversation = inbox.messages.find_by(source_id: 'LATER').conversation
      expect(conversation.unread_incoming_messages).to be_empty
    end

    # On a thread that already existed an unread message is somebody's real backlog, and an
    # import has no business marking it read.
    it 'leaves an existing thread its own unread messages' do
      contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: "#{lid}@lid")
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: lid)
      conversation = create(:conversation, inbox: inbox, account: inbox.account, contact: contact,
                                           status: :resolved, agent_last_seen_at: nil)
      create(:message, conversation: conversation, inbox: inbox, account: inbox.account,
                       message_type: :incoming, content: 'unread')

      import([raw_message('OLD', sent_at: 10.days.ago)], watermark: 3.days.ago)

      expect(conversation.reload.unread_incoming_messages).not_to be_empty
    end

    # A thread that already existed holds something real, and an archive filed into it says
    # nothing about when it was last active: left to the ordinary callback, an import would
    # drag a conversation answered this morning back to last year and to the bottom of the
    # list.
    it 'never drags an existing thread backwards' do
      contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: "#{lid}@lid")
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: lid)
      conversation = create(:conversation, inbox: inbox, account: inbox.account, contact: contact,
                                           last_activity_at: 1.hour.ago)

      import([raw_message('A', sent_at: 10.days.ago)], watermark: 3.days.ago)

      expect(inbox.messages.find_by(source_id: 'A').conversation_id).to eq(conversation.id)
      expect(conversation.reload.last_activity_at).to be_within(2.seconds).of(1.hour.ago)
    end
  end

  # The shape every other example here skips: a history key is raw protobuf, four fields,
  # and the addressing a live key carries is stamped by the decoder from a stanza a dump
  # does not have. So on an account addressed by LID the chat arrives as `<lid>@lid` alone,
  # and the LID is digits -- which is how it used to be filed as the contact's phone
  # number. Reported at fazer-ai/chatwoot#408, with contacts created as `+235085806727321`.
  describe 'a chat addressed by LID with no mapping alongside it' do
    def bare_message(id, sent_at:)
      {
        key: { id: id, remoteJid: jid, fromMe: false },
        messageTimestamp: sent_at.to_i,
        message: { conversation: "message #{id}" }
      }.with_indifferent_access
    end

    it 'files the chat without inventing a phone number for it' do
      import([bare_message('RAW', sent_at: 10.days.ago)], watermark: 3.days.ago)

      contact = inbox.messages.find_by(source_id: 'RAW').conversation.contact
      expect(contact.phone_number).to be_nil
      expect(contact.identifier).to eq("#{lid}@lid")
    end

    # The LID is still the address, so the chat is keyed by it and the import proceeds --
    # only the phone number is withheld, and the first live message fills it in.
    it 'keys the chat by its LID' do
      import([bare_message('RAW', sent_at: 10.days.ago)], watermark: 3.days.ago)

      expect(inbox.contact_inboxes.pluck(:source_id)).to eq([lid])
    end
  end

  # Same class, one level down: a group's author is addressed the same two ways, and its
  # LID is digits too.
  describe 'a group author addressed by LID with no mapping alongside it' do
    before { allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:groups_enabled?).and_return(true) }

    it 'files the author without inventing a phone number for them' do
      import(
        [{
          key: { id: 'GRP', remoteJid: '120363000000000000@g.us', participant: jid, fromMe: false },
          messageTimestamp: 10.days.ago.to_i,
          message: { conversation: 'hello group' }
        }.with_indifferent_access],
        watermark: 3.days.ago
      )

      sender = inbox.messages.find_by(source_id: 'GRP').sender
      expect(sender.phone_number).to be_nil
      expect(sender.identifier).to eq("#{lid}@lid")
    end
  end

  # A dump strips `groupName` from every message, and no `groups.update` follows it, so
  # before this an imported group was filed under its own jid and only a later live event
  # ever fixed it: 34 of 46 groups on a real pairing.
  describe 'what an imported group is called' do
    let(:group_jid) { '120363000000000000@g.us' }

    before { allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:groups_enabled?).and_return(true) }

    def group_message(id)
      {
        key: { id: id, remoteJid: group_jid, participant: jid, fromMe: false },
        messageTimestamp: 10.days.ago.to_i,
        message: { conversation: "in the group, #{id}" }
      }.with_indifferent_access
    end

    it 'takes the subject the dump carries' do
      import([group_message('GRP')], watermark: 3.days.ago, group_name: 'Obra da casa')

      expect(inbox.messages.find_by(source_id: 'GRP').conversation.contact.name).to eq('Obra da casa')
    end

    # What a bridge too old to send the subjects produces, and what every import did before
    # this: the group is still filed, it just has nothing to be called by.
    it 'falls back to the jid when the dump names no group' do
      import([group_message('GRP')], watermark: 3.days.ago)

      expect(inbox.messages.find_by(source_id: 'GRP').conversation.contact.name).to eq('120363000000000000')
    end

    # The frames of one dump are separate jobs, and the groups already sitting under a jid
    # from an earlier pairing are the whole backlog this has to clear.
    it 'renames a group an earlier import left under its jid' do
      import([group_message('FIRST')], watermark: 3.days.ago)
      import([group_message('SECOND')], watermark: 3.days.ago, group_name: 'Obra da casa')

      expect(inbox.messages.find_by(source_id: 'FIRST').conversation.contact.name).to eq('Obra da casa')
    end

    # And this is the shape that backlog actually arrives in: the group is numbered
    # precisely because its messages are already stored, so the dump that finally names it
    # has nothing new to file. Renaming only alongside a write would skip every one of them.
    it 'renames a group whose dump carries nothing it has not already stored' do
      import([group_message('ONLY')], watermark: 3.days.ago)
      import([group_message('ONLY')], watermark: 3.days.ago, group_name: 'Obra da casa')

      expect(inbox.messages.find_by(source_id: 'ONLY').conversation.contact.name).to eq('Obra da casa')
    end

    # Markers are the ordinary content of a numbered group's slice, not an exception: 519 of
    # 614 threads on a real pairing had nothing else. A rename that waited for something
    # writable would skip most of the backlog it exists to clear.
    it 'renames a group whose whole slice is markers' do
      import([group_message('REAL')], watermark: 3.days.ago)
      marker = group_message('STUB').merge('messageStubType' => 2)

      import([marker], watermark: 3.days.ago, group_name: 'Obra da casa')

      expect(inbox.messages.find_by(source_id: 'REAL').conversation.contact.name).to eq('Obra da casa')
    end

    # The subject was read when the frame was queued, and the frames carry no ordering: a
    # `groups.update` may have renamed the group in between, and this has no way to tell.
    # So it only ever replaces the placeholder -- a group that already has a name has the
    # live path keeping it current, and a blind second writer on that field would undo it.
    it 'leaves a group that already has a name alone' do
      import([group_message('REAL')], watermark: 3.days.ago, group_name: 'Nome atual')
      marker = group_message('STUB').merge('messageStubType' => 2)

      import([marker], watermark: 3.days.ago, group_name: 'Nome de ontem')

      expect(inbox.messages.find_by(source_id: 'REAL').conversation.contact.name).to eq('Nome atual')
    end

    # The kill switch is about the subsystem and not about writing rows. A dump reaches a
    # build that handles no groups either way -- the bridge filters live traffic, not
    # history -- and renaming the contact an earlier pairing left behind is as much group
    # processing as filing the messages is.
    it 'leaves the group alone when the build handles no groups' do
      import([group_message('FIRST')], watermark: 3.days.ago)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:groups_enabled?).and_return(false)

      import([group_message('SECOND')], watermark: 3.days.ago, group_name: 'Obra da casa')

      expect(inbox.messages.find_by(source_id: 'FIRST').conversation.contact.name).to eq('120363000000000000')
      expect(inbox.messages.pluck(:source_id)).to eq(%w[FIRST])
    end

    # The same rule on the other path in: a frame that does have messages to file goes
    # through `find_or_create_group_contact`, which renames unconditionally. An import must
    # not overwrite a name there either, and the stale subject is just as stale.
    it 'leaves a named group alone even when the frame has messages to file' do
      import([group_message('REAL')], watermark: 3.days.ago, group_name: 'Nome atual')

      import([group_message('NOVA')], watermark: 3.days.ago, group_name: 'Nome de ontem')

      expect(inbox.messages.find_by(source_id: 'NOVA').conversation.contact.name).to eq('Nome atual')
    end
  end

  # Not filed: they mutate a row that has to exist, and replaying them out of a dump either
  # no-ops or acts on a row a later message in the same dump has not written yet.
  it 'skips the entries that are not messages' do
    revoke = { protocolMessage: { type: 'REVOKE', key: { id: 'TARGET' } } }
    import([raw_message('REV', sent_at: 2.days.ago, message: revoke)], watermark: 3.days.ago)

    expect(inbox.messages).to be_empty
  end
end
