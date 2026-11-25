require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::MessageRevoked do
  subject(:dispatch) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) }

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:conversation) { create(:conversation, inbox: inbox, account: channel.account) }
  let(:message) do
    create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                     content: 'mensagem original', source_id: '3EB0AAAA0001')
  end
  let(:by) { 'contact' }
  let(:event) do
    model::Event.build(
      model::Events::MessageRevoked.new(chat: model::Address.phone('5541999990000'),
                                        message_id: message.source_id, by: by)
    )
  end

  # A shared-contact payload is stored as one row per card, all under the provider's
  # single id. Revoking only the row `find_by` happened to return left the other cards
  # on screen after the contact deleted the share.
  context 'when the id covers every card of a shared-contact message' do
    let!(:second_card) do
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       content: 'Bruno Lima', source_id: message.source_id)
    end

    it 'revokes all of them' do
      expect(dispatch).to eq(:handled)

      expect(message.reload.deleted_by_contact).to be(true)
      expect(second_card.reload.deleted_by_contact).to be(true)
    end
  end

  it 'flags a contact revoke without losing the content' do
    expect(dispatch).to eq(:handled)

    expect(message.reload.deleted_by_contact).to be(true)
    expect(message.content).to eq('mensagem original')
  end

  # WhatsApp addresses a message by (id, participant), so a deletion's key names an author
  # and the phones apply nothing when that name is wrong. Any member of a group can send
  # one naming somebody who did not write the message: every phone goes on showing it, and
  # this side used to mark it deleted for the agent alone.
  describe 'the author the key claims' do
    let(:author) { model::Party.new(phone: '5541988887777', lid: '998877665544332') }
    let(:claimed) { author }
    let(:writer) do
      contact = create(:contact, account: channel.account, phone_number: '+5541988887777',
                                 identifier: '998877665544332@lid')
      create(:contact_inbox, contact: contact, inbox: inbox, source_id: '998877665544332')
      contact
    end
    let(:message) do
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       content: 'mensagem original', source_id: '3EB0AAAA0001',
                       message_type: :incoming, sender: writer)
    end
    let(:event) do
      model::Event.build(
        model::Events::MessageRevoked.new(chat: model::Address.group('120363041234567890'),
                                          message_id: message.source_id, message_author: claimed, by: by)
      )
    end

    it 'applies the deletion when the claim names who wrote it' do
      expect(dispatch).to eq(:handled)

      expect(message.reload.deleted_by_contact).to be(true)
    end

    context 'when the claim names somebody else in the group' do
      let(:claimed) { model::Party.new(phone: '5541977776666', lid: '111222333444555') }

      before do
        other = create(:contact, account: channel.account, phone_number: '+5541977776666',
                                 identifier: '111222333444555@lid')
        create(:contact_inbox, contact: other, inbox: inbox, source_id: '111222333444555')
      end

      it 'leaves the message alone, as every phone in the group does' do
        expect(dispatch).to eq(:ignored)

        expect(message.reload.deleted_by_contact).to be_nil
      end
    end

    # Filing them would invent a contact out of an assertion nothing has checked, and a
    # name this inbox has never seen cannot be the person who wrote the message.
    context 'when the claim names somebody this inbox has never seen' do
      let(:claimed) { model::Party.new(phone: '5541966665555', lid: '555444333222111') }

      it 'leaves the message alone and files nobody' do
        message # the writer's own contact_inbox belongs to the fixture, not to the dispatch

        expect { expect(dispatch).to eq(:ignored) }.not_to change(inbox.contact_inboxes, :count)

        expect(message.reload.deleted_by_contact).to be_nil
      end
    end

    # `ContactLookup` prefers the LID-keyed row on purpose, so while the same person still
    # holds both a phone-keyed row and a LID-keyed one, resolving the claim answers with
    # the copy the message does not point at, and a valid deletion would be refused for
    # the whole window.
    context 'when the author still holds a second row under the other key' do
      let(:writer) do
        contact = create(:contact, account: channel.account, phone_number: '+5541988887777')
        create(:contact_inbox, contact: contact, inbox: inbox, source_id: '5541988887777')
        contact
      end

      before do
        consolidating = create(:contact, account: channel.account, identifier: '998877665544332@lid')
        create(:contact_inbox, contact: consolidating, inbox: inbox, source_id: '998877665544332')
      end

      it 'applies the deletion, because the claim names the row that holds the message' do
        expect(dispatch).to eq(:handled)

        expect(message.reload.deleted_by_contact).to be(true)
      end
    end

    # Each key a contact can answer to, on its own, because a row that holds only one of
    # them is a real row: consolidation writes the identifier, the phone arrives with the
    # first message, and the contact_inbox key is whichever WhatsApp used that day.
    context 'when the author holds only the LID on its identifier' do
      let(:writer) { create(:contact, account: channel.account, identifier: '998877665544332@lid') }

      it 'applies the deletion' do
        expect(dispatch).to eq(:handled)

        expect(message.reload.deleted_by_contact).to be(true)
      end
    end

    context 'when the author holds only a phone number' do
      let(:writer) { create(:contact, account: channel.account, phone_number: '+5541988887777') }

      it 'applies the deletion' do
        expect(dispatch).to eq(:handled)

        expect(message.reload.deleted_by_contact).to be(true)
      end
    end

    # WhatsApp treats a LID and a phone number as different identities even when their
    # digits are equal, and the claim is written by whoever sent the deletion: comparing
    # bare digits across the two namespaces lets a group member name a phone whose digits
    # are the victim's LID and walk straight through the check.
    context 'when the claim names a phone whose digits are the author\'s LID' do
      let(:writer) { create(:contact, account: channel.account, identifier: '998877665544332@lid') }
      let(:claimed) { model::Party.new(phone: '998877665544332') }

      it 'leaves the message alone' do
        expect(dispatch).to eq(:ignored)

        expect(message.reload.deleted_by_contact).to be_nil
      end
    end

    context 'when the claim names a LID whose digits are the author\'s number' do
      let(:writer) { create(:contact, account: channel.account, phone_number: '+5541988887777') }
      let(:claimed) { model::Party.new(lid: '5541988887777') }

      it 'leaves the message alone' do
        expect(dispatch).to eq(:ignored)

        expect(message.reload.deleted_by_contact).to be_nil
      end
    end

    # One source id can hold rows belonging to different people across the inbox, and now
    # that a claim rules some of them out, the first row is not always one that moved.
    context 'when the id also covers a row belonging to somebody else' do
      let!(:other_conversation) { create(:conversation, inbox: inbox, account: channel.account) }
      # Created before the claimed author's row and named by the literal id, so it is the
      # one `find_messages` returns first: taking the first row's conversation has to be
      # visibly wrong here, and it is not if the row that moved happens to lead.
      let!(:someone_elses) do
        stranger = create(:contact, account: channel.account, identifier: '111222333444555@lid')
        create(:message, conversation: other_conversation, inbox: inbox, account: channel.account,
                         content: 'de outra pessoa', source_id: '3EB0AAAA0001',
                         message_type: :incoming, sender: stranger)
      end

      it 'revokes only the row whose author the claim names' do
        expect(dispatch).to eq(:handled)

        expect(message.reload.deleted_by_contact).to be(true)
        expect(someone_elses.reload.deleted_by_contact).to be_nil
      end

      it 'refreshes the card of the conversation it changed, not the first one it found' do
        expect(someone_elses.id).to be < message.id
        [conversation, other_conversation].each do |thread|
          thread.update_columns(updated_at: 1.hour.ago) # rubocop:disable Rails/SkipsModelValidations
        end

        dispatch

        expect(conversation.reload.updated_at).to be > 1.minute.ago
        expect(other_conversation.reload.updated_at).to be < 1.minute.ago
      end
    end

    # What the row recorded about who wrote it, which is the only answer that does not
    # move. A contact is what the person is called here today; the identity is what
    # WhatsApp called them when the message arrived.
    context 'when the row recorded who wrote it' do
      let(:writer) do
        contact = create(:contact, account: channel.account, phone_number: '+5541988887777',
                                   identifier: '998877665544332@lid')
        create(:contact_inbox, contact: contact, inbox: inbox, source_id: '998877665544332')
        contact
      end
      let(:message) do
        create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                         content: 'mensagem original', source_id: '3EB0AAAA0001',
                         message_type: :incoming, sender: writer,
                         content_attributes: { 'external_author' => { 'phone' => '5541988887777',
                                                                      'lid' => '998877665544332' } })
      end

      it 'applies the deletion after an agent edited the contact out of recognition' do
        writer.update!(phone_number: '+5541900000000', identifier: nil)

        expect(dispatch).to eq(:handled)

        expect(message.reload.deleted_by_contact).to be(true)
      end

      # The recorded identity wins, or it would only ever be a second chance to match and
      # never a correction of the first.
      it 'refuses a claim the row does not name, whatever the contact answers to now' do
        writer.update!(phone_number: '+5541977776666', identifier: '111222333444555@lid')

        Whatsapp::Session::Inbound::Dispatcher.dispatch(
          channel,
          model::Event.build(model::Events::MessageRevoked.new(
                               chat: model::Address.group('120363041234567890'), message_id: message.source_id,
                               message_author: model::Party.new(phone: '5541977776666', lid: '111222333444555'),
                               by: 'contact'
                             ))
        )

        expect(message.reload.deleted_by_contact).to be_nil
      end

      # The contract lets an event carry just one of the two, so a snapshot can hold a
      # namespace the claim does not use. It answers in the ones it holds and stays out of
      # the way in the others, or a valid deletion would be turned down by a record that
      # never knew.
      context 'when the claim names an alias the row never recorded' do
        let(:message) do
          create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                           content: 'mensagem original', source_id: '3EB0AAAA0001',
                           message_type: :incoming, sender: writer,
                           content_attributes: { 'external_author' => { 'lid' => '998877665544332' } })
        end
        let(:claimed) { model::Party.new(phone: '5541988887777') }

        it 'falls back to the contact rather than refusing' do
          expect(dispatch).to eq(:handled)

          expect(message.reload.deleted_by_contact).to be(true)
        end
      end

      # The fallback the snapshot steps aside for is the namespaced one, so the digits of
      # a LID are still not a phone number there either.
      context 'when the claim wears the recorded LID as a phone the row never saw' do
        let(:writer) { create(:contact, account: channel.account, identifier: '998877665544332@lid') }
        let(:message) do
          create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                           content: 'mensagem original', source_id: '3EB0AAAA0001',
                           message_type: :incoming, sender: writer,
                           content_attributes: { 'external_author' => { 'lid' => '998877665544332' } })
        end
        let(:claimed) { model::Party.new(phone: '998877665544332') }

        it 'leaves the message alone' do
          expect(dispatch).to eq(:ignored)

          expect(message.reload.deleted_by_contact).to be_nil
        end
      end

      # The phone half of that decides on its own: a snapshot holding only a number still
      # answers a claim that names only a number, and answering is the whole point when
      # the contact has since been edited into agreeing with the claim.
      context 'when the row recorded only a number and the claim names another' do
        let(:writer) { create(:contact, account: channel.account, phone_number: '+5541988887777') }
        let(:message) do
          create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                           content: 'mensagem original', source_id: '3EB0AAAA0001',
                           message_type: :incoming, sender: writer,
                           content_attributes: { 'external_author' => { 'phone' => '5541988887777' } })
        end
        let(:claimed) { model::Party.new(phone: '5541977776666') }

        it 'refuses it even once the contact answers to that number' do
          writer.update!(phone_number: '+5541977776666')

          expect(dispatch).to eq(:ignored)

          expect(message.reload.deleted_by_contact).to be_nil
        end
      end

      context 'when the claim names a phone whose digits are the recorded LID' do
        let(:claimed) { model::Party.new(phone: '998877665544332') }

        it 'leaves the message alone' do
          expect(dispatch).to eq(:ignored)

          expect(message.reload.deleted_by_contact).to be_nil
        end
      end
    end

    # A blank claim is what a direct chat sends, and what a producer that predates the
    # field sends for everything: it has to go on meaning today's behaviour.
    context 'when the key named nobody' do
      let(:claimed) { nil }

      it 'applies the deletion' do
        expect(dispatch).to eq(:handled)

        expect(message.reload.deleted_by_contact).to be(true)
      end
    end

    # An outgoing row carries the agent who typed it, and WhatsApp attributes it to the
    # connected account: the pairing keys are what answers, not the agent's user record.
    context 'when the message is one this account wrote' do
      let(:message) do
        create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                         content: 'mensagem original', source_id: '3EB0AAAA0001', message_type: :outgoing)
      end

      # Merged rather than replaced: the factory puts what the dispatcher's own guards read
      # in there, and swapping the hash wholesale skips the event before it reaches here.
      before do
        channel.update!(provider_connection: channel.provider_connection.merge(
          'phone_number' => '5541999990000', 'lid' => '20000000000002'
        ))
      end

      context 'when the claim names this account' do
        let(:claimed) { model::Party.new(phone: '5541999990000', lid: '20000000000002') }

        it 'applies the deletion' do
          expect(dispatch).to eq(:handled)

          expect(message.reload.deleted_by_contact).to be(true)
        end
      end

      context 'when the claim names a member of the group instead' do
        it 'leaves the message alone' do
          expect(dispatch).to eq(:ignored)

          expect(message.reload.deleted_by_contact).to be_nil
        end
      end
    end
  end

  # The frame below is not written by hand: it was captured from the connector's own live
  # group phase against two real accounts on 08/09/2026, at 292a2a6, which is the commit
  # this contract is vendored from. Every other example here builds the payload through
  # the model, so a field arriving under a name the model does not read would leave all of
  # them green and this check dead in production.
  #
  # What it also happens to be is the case this whole comparison has to let through: an
  # admin deleting somebody else's message. `sender` is the admin who pressed delete and
  # `message_author` is the member who wrote it, and they are different people.
  describe 'a frame measured off a real group deletion' do
    let(:frame) do
      {
        'v' => 1, 'id' => '01920000-0000-7000-8000-0000000000f1', 'type' => 'message.revoked',
        'sid' => '9f1c0f4e-6a2b-4c8e-9d1a-2b3c4d5e6f70', 'epoch' => 7, 'seq' => 241, 'ts' => 1_788_907_604_000,
        'payload' => {
          'chat' => { 'kind' => 'group', 'id' => '120363400000000002' },
          'sender' => { 'phone' => '5511999990001', 'lid' => '20000000000002', 'verified_name' => 'Contato Exemplo' },
          'message_id' => '3EB0647797816A5B93E5B1',
          'message_author' => { 'phone' => '5511999990002', 'lid' => '30000000000003' },
          'by' => 'contact', 'timestamp' => 1_788_907_604_000
        }
      }
    end
    let(:event) { model::Event.from_frame(frame) }
    let!(:message) do
      author = create(:contact, account: channel.account, phone_number: '+5511999990002',
                                identifier: '30000000000003@lid')
      create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                       content: 'mensagem original', source_id: '3EB0647797816A5B93E5B1',
                       message_type: :incoming, sender: author)
    end

    it 'reads the author off the wire and applies the admin deletion' do
      expect(event.payload.message_author.lid).to eq('30000000000003')

      expect(dispatch).to eq(:handled)

      expect(message.reload.deleted_by_contact).to be(true)
    end

    # The same frame with the key naming the admin who pressed delete instead of the member
    # who wrote it, which is the shape #486 measured WhatsApp refusing.
    it 'refuses the same deletion once the key names somebody who did not write it' do
      frame['payload']['message_author'] = { 'phone' => '5511999990001', 'lid' => '20000000000002' }

      expect(dispatch).to eq(:ignored)

      expect(message.reload.deleted_by_contact).to be_nil
    end
  end

  context 'when it was deleted from the connected phone' do
    let(:by) { 'self' }

    it 'marks the message deleted the same way Chatwoot does' do
      expect(dispatch).to eq(:handled)

      expect(message.reload).to be_deleted
      expect(message.content).to eq(I18n.t('conversations.messages.deleted'))
    end

    # The messages controller destroys them, and leaving them behind would keep the
    # deleted media readable through the API and in storage.
    it 'takes the attachments with it' do
      message.attachments.create!(account_id: message.account_id, file_type: :image)

      expect(dispatch).to eq(:handled)
      expect(message.reload.attachments).to be_empty
    end

    it 'ignores the echo of a deletion Chatwoot already applied' do
      message.update!(content: '', content_attributes: message.content_attributes.merge('deleted' => true))

      expect(dispatch).to eq(:ignored)
    end
  end
end
