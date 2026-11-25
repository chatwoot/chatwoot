require 'rails_helper'

describe Whatsapp::BaileysHandlers::MessagingHistorySet do
  let(:webhook_verify_token) { 'valid_token' }
  let!(:whatsapp_channel) do
    create(:channel_whatsapp,
           provider: 'baileys',
           provider_config: { webhook_verify_token: webhook_verify_token },
           validate_provider_config: false,
           received_messages: false)
  end
  let(:inbox) { whatsapp_channel.inbox }

  def raw_message(id, jid, timestamp: 2.days.ago.to_i)
    {
      key: { id: id, remoteJid: jid, fromMe: false },
      messageTimestamp: timestamp,
      message: { conversation: "message #{id}" }
    }
  end

  def perform(data)
    params = { webhookVerifyToken: webhook_verify_token, event: 'messaging-history.set', data: data }
    Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
  end

  describe 'the syncType gate' do
    # RECENT is WhatsApp replaying what arrived while the device was offline, which is the
    # whole reason this provider still gets the feature.
    it 'files a dump that carries conversation' do
      expect do
        perform({ syncType: 3, messages: [raw_message('A', '5511912345678@s.whatsapp.net')] })
      end.to have_enqueued_job(Whatsapp::Baileys::HistoryImportJob)
    end

    it 'drops the types that carry no message' do
      [1, 4, 5].each do |sync_type|
        expect do
          perform({ syncType: sync_type, messages: [raw_message('A', '5511912345678@s.whatsapp.net')] })
        end.not_to have_enqueued_job(Whatsapp::Baileys::HistoryImportJob)
      end
    end

    it 'files a dump from a bridge that does not classify it' do
      expect do
        perform({ messages: [raw_message('A', '5511912345678@s.whatsapp.net')] })
      end.to have_enqueued_job(Whatsapp::Baileys::HistoryImportJob)
    end
  end

  # The subject travels on the frame because the messages do not carry it, and it has to
  # survive the trip through the queue: an argument list is a serialization contract, and
  # the group would otherwise reach the importer nameless after a round trip that looked
  # fine in every unit test.
  it 'hands the worker what the groups in the dump are called' do
    group_jid = '120363000000000000@g.us'

    perform({ syncType: 3, messages: [raw_message('A', group_jid)],
              groupNames: { group_jid => 'Obra da casa' } })

    expect(Whatsapp::Baileys::HistoryImportJob).to have_been_enqueued.with(
      inbox, anything, anything, anything, hash_including(group_name: 'Obra da casa')
    )
  end

  # The same claim, made against the round trip rather than the call: the enqueue above
  # reads the arguments in memory, where a keyword that the queue mangles still looks right.
  it 'names the group once the worker has run' do
    group_jid = '120363000000000000@g.us'
    allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:groups_enabled?).and_return(true)

    perform_enqueued_jobs(only: Whatsapp::Baileys::HistoryImportJob) do
      # ON_DEMAND, so the archive half is kept: this inbox never asked for standing consent
      # and the dump has no coverage to sit newer than.
      perform({ syncType: 6,
                messages: [raw_message('A', group_jid).deep_merge(key: { participant: '5511912345678@s.whatsapp.net' })],
                groupNames: { group_jid => 'Obra da casa' } })
    end

    expect(inbox.messages.find_by(source_id: 'A').conversation.contact.name).to eq('Obra da casa')
  end

  # One job per chat, so a chat locked by live traffic retries alone instead of holding up
  # the rest of the import.
  it 'hands each chat to its own worker' do
    expect do
      perform({ syncType: 3,
                messages: [
                  raw_message('A', '5511912345678@s.whatsapp.net'),
                  raw_message('B', '5511912345678@s.whatsapp.net'),
                  raw_message('C', '5511998887777@s.whatsapp.net')
                ] })
    end.to have_enqueued_job(Whatsapp::Baileys::HistoryImportJob).twice
  end

  # WhatsApp's own service-notice account. Baileys' jid filter only sees live traffic, so a
  # full sync replays years of these, and every one asks the legacy pipeline for a contact
  # whose phone number is `+0`. Measured on a real pairing: 79 rows, 8 dead jobs.
  it 'files nothing for the account no contact can be built from' do
    expect do
      perform({ syncType: 3,
                messages: [
                  raw_message('A', '0@s.whatsapp.net'),
                  raw_message('B', '5511912345678@s.whatsapp.net')
                ] })
    end.to have_enqueued_job(Whatsapp::Baileys::HistoryImportJob).once
  end

  describe 'whether anybody asked' do
    # The phone answering a question we put to it identifies its own answer, so no window
    # has to hold that fact across the round trip.
    it 'counts an on-demand answer as requested' do
      perform({ syncType: 6, messages: [raw_message('A', '5511912345678@s.whatsapp.net')] })

      expect(Whatsapp::Baileys::HistoryImportJob).to have_been_enqueued.with(inbox, anything, anything, true, hash_including(announce: anything))
    end

    it 'counts standing consent on the inbox as requested' do
      whatsapp_channel.update!(provider_config: whatsapp_channel.provider_config.merge('history_sync' => true))

      perform({ syncType: 0, messages: [raw_message('A', '5511912345678@s.whatsapp.net')] })

      expect(Whatsapp::Baileys::HistoryImportJob).to have_been_enqueued.with(inbox, anything, anything, true, hash_including(announce: anything))
    end

    it 'counts an open backfill window as requested, and holds it open for the next frame' do
      Whatsapp::Session::HistoryBackfill.open!(whatsapp_channel)

      perform({ syncType: 0, messages: [raw_message('A', '5511912345678@s.whatsapp.net')] })

      expect(Whatsapp::Baileys::HistoryImportJob).to have_been_enqueued.with(inbox, anything, anything, true, hash_including(announce: anything))
      expect(Whatsapp::Session::HistoryBackfill.pending?(whatsapp_channel)).to be(true)
    end

    # The pairing dump nobody asked for. It is still handed over, because its gap half is
    # the only copy of what was missed; the importer is what keeps the archive out.
    it 'is unrequested when the phone volunteered it' do
      perform({ syncType: 0, messages: [raw_message('A', '5511912345678@s.whatsapp.net')] })

      expect(Whatsapp::Baileys::HistoryImportJob).to have_been_enqueued.with(inbox, anything, anything, false, hash_including(announce: anything))
    end
  end

  # ON_DEMAND only ever answers a request we sent, and the only thing that sends one is an
  # operator pressing for older messages inside a thread. So the archive it carries lands
  # announced, or the press does nothing visible until the page is reloaded.
  describe 'whether anybody is watching it land' do
    it 'announces the answer to a press' do
      perform({ syncType: 6, messages: [raw_message('A', '5511912345678@s.whatsapp.net')] })

      expect(Whatsapp::Baileys::HistoryImportJob)
        .to have_been_enqueued.with(inbox, anything, anything, anything, hash_including(announce: true))
    end

    # The pairing dump, which is a year of somebody else's conversations arriving at once
    # with nobody watching. Every type but ON_DEMAND takes this branch.
    it 'keeps a dump the phone volunteered silent' do
      perform({ syncType: 0, messages: [raw_message('A', '5511912345678@s.whatsapp.net')] })

      expect(Whatsapp::Baileys::HistoryImportJob)
        .to have_been_enqueued.with(inbox, anything, anything, anything, hash_including(announce: false))
    end
  end

  # Read once, before any worker runs: they import in parallel, and a boundary read inside
  # them would be measured against what the workers that went first had already written.
  it 'decides the coverage boundary once, for the whole frame' do
    conversation = create(:conversation, inbox: inbox, account: inbox.account)
    stored = create(:message, conversation: conversation, inbox: inbox, source_id: 'OLD', created_at: 3.days.ago)

    perform({ syncType: 3,
              messages: [
                raw_message('A', '5511912345678@s.whatsapp.net'),
                raw_message('C', '5511998887777@s.whatsapp.net')
              ] })

    watermarks = enqueued_jobs.filter_map { |job| job['arguments'][2] if job['job_class'] == 'Whatsapp::Baileys::HistoryImportJob' }
    expect(watermarks.uniq.size).to eq(1)
    expect(Time.zone.parse(watermarks.first['value'])).to be_within(1.second).of(stored.created_at)
  end

  # The only way WhatsApp ever says a chat is finished, and it says it on the answer to a
  # request and nowhere else.
  describe 'the chat WhatsApp says is finished' do
    let(:contact) { create(:contact, account: inbox.account, phone_number: '+5511912345678') }
    let!(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '5511912345678') }
    let!(:conversation) { create(:conversation, inbox: inbox, contact: contact, contact_inbox: contact_inbox, account: inbox.account) }

    it 'records the answer on the thread' do
      perform({ syncType: 6, messages: [], exhausted: ['5511912345678@s.whatsapp.net'] })

      expect(conversation.reload.additional_attributes['history_exhausted']).to be(true)
    end

    # A request addressed to a LID comes back answered as `<phone>@s.whatsapp.net`, so the
    # domain the answer carries is not the one the request used.
    it 'matches the chat by id whichever domain the answer carries' do
      perform({ syncType: 6, messages: [], exhausted: ['5511912345678@lid'] })

      expect(conversation.reload.additional_attributes['history_exhausted']).to be(true)
    end

    # The case the equality match could not reach, and the one that actually happens: a row
    # keyed by the LID, answered by the phone. Consolidation re-keys a contact inbox to its
    # LID and the phone survives only on the contact, so the two ids are different strings
    # and stripping the domain does not bring them together.
    context 'when the row is keyed by the LID and the answer comes addressed by the phone' do
      let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '199887766554433') }

      it 'still records the answer on the thread' do
        perform({ syncType: 6, messages: [], exhausted: ['5511912345678@s.whatsapp.net'] })

        expect(conversation.reload.additional_attributes['history_exhausted']).to be(true)
      end
    end

    # Brazilian and Argentinian numbers have two spellings, and which one a row carries
    # depends on who wrote it first.
    context 'when the row carries the other ninth-digit spelling' do
      let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '551112345678') }

      it 'still records the answer on the thread' do
        perform({ syncType: 6, messages: [], exhausted: ['5511912345678@s.whatsapp.net'] })

        expect(conversation.reload.additional_attributes['history_exhausted']).to be(true)
      end
    end

    it 'leaves the thread alone when no chat was flagged' do
      perform({ syncType: 6, messages: [raw_message('A', '5511912345678@s.whatsapp.net')] })

      expect(conversation.reload.additional_attributes).not_to have_key('history_exhausted')
    end

    it 'ignores a chat this inbox has no contact for' do
      expect do
        perform({ syncType: 6, messages: [], exhausted: ['5511900000000@s.whatsapp.net'] })
      end.not_to raise_error
    end
  end
end
