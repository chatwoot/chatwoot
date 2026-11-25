require 'rails_helper'

# The connector's slices: one chat each, typed by `sync`, with the chat's name and whether
# the phone has anything older.
RSpec.describe Whatsapp::Session::Inbound::Handlers::HistorySync do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:slots) { Whatsapp::Session::Inbound::ImportSlots }
  let(:phone) { '5541999990000' }
  let(:lid) { '182736451928374' }
  let(:chat) { model::Address.phone(phone) }
  let(:sender) { model::Party.new(phone: phone, lid: lid, push_name: 'Ana Souza') }

  after { Redis::Alfred.delete(slots::KEY) }

  def historical(id, at, chat: self.chat, content: nil)
    model::InboundMessage.new(
      id: id, chat: chat, sender: sender, from_me: false, timestamp: (at.to_f * 1000).to_i,
      content: content || model::Content::Text.new(body: "mensagem #{id}")
    )
  end

  def slice(messages, sync: 'on_demand', chat: self.chat, name: nil, exhausted: nil)
    data = { 'sync' => sync, 'chat' => chat.to_h, 'messages' => messages.map(&:to_h) }
    data['name'] = name if name
    data['exhausted'] = exhausted unless exhausted.nil?
    model::Event.build(model::Events::HistorySync.new(kind: 'messages', data: data))
  end

  def dispatch(frame) = Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, frame)
  def deliver(frame) = perform_enqueued_jobs(only: Whatsapp::Session::HistoryImportJob) { dispatch(frame) }
  def import_jobs = enqueued_jobs.select { |job| job['job_class'] == 'Whatsapp::Session::HistoryImportJob' }

  def threads_of(contact, source_id, statuses)
    contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox, source_id: source_id)
    statuses.map do |status|
      create(:conversation, inbox: inbox, account: inbox.account, contact: contact, contact_inbox: contact_inbox, status: status)
    end
  end

  def a_contact(number = phone, **attributes)
    create(:contact, account: inbox.account, phone_number: "+#{number}", **attributes)
  end

  def cover!(at)
    other = create(:conversation, inbox: inbox, account: inbox.account)
    create(:message, conversation: other, inbox: inbox, account: inbox.account, source_id: "LIVE#{SecureRandom.hex(4)}", created_at: at)
  end

  def exhausted?(conversation) = conversation.reload.additional_attributes&.dig('history_exhausted') == true

  describe 'off the consumer thread' do
    let(:frame) { slice(Array.new(100) { |index| historical(format('3EB0S%03d', index), (200 - index).minutes.ago) }, sync: 'recent') }

    before { channel.update!(provider_config: channel.provider_config.merge('history_sync' => true)) }

    it 'queues one import for the slice and writes nothing on the thread that read it' do
      expect(dispatch(frame)).to eq(:handled)

      expect(inbox.messages.count).to eq(0)
      expect(import_jobs.size).to eq(1)

      perform_enqueued_jobs(only: Whatsapp::Session::HistoryImportJob)
      expect(inbox.messages.count).to eq(100)
    end

    # A worker can take the slice the moment it is enqueued, so it is on record as pending
    # before that, and a slice filed at once leaves nothing pending behind it.
    it 'leaves nothing pending once the slice is filed, however fast that happens' do
      deliver(frame)

      expect(inbox.messages.count).to eq(100)
      expect(Whatsapp::Session::HistoryImportJob.pending?(inbox)).to be(false)
    end

    # The key lives as long as slices keep arriving, so a lost one is dropped by its age.
    it 'forgets a slice that never finished once it is older than a day' do
      importer = Whatsapp::Session::HistoryImportJob
      importer.queued(inbox, 'lost-job')
      travel(importer::PENDING_TTL - 1.hour)
      importer.queued(inbox, 'later-job')
      importer.finished(inbox, 'later-job')
      travel(2.hours)

      expect(importer.pending?(inbox)).to be(false)
    ensure
      Redis::Alfred.delete(Whatsapp::Session::HistoryImportJob.pending_key(inbox))
    end

    it 'waits for an import slot, and files the slice once one is given back' do
      tokens = Array.new(slots.concurrency) { |index| "held-#{index}" }
      Redis::Alfred.with { |conn| tokens.each { |token| conn.zadd(slots::KEY, Time.now.to_f + 300, token) } }

      dispatch(frame)
      perform_enqueued_jobs(only: Whatsapp::Session::HistoryImportJob, queue: 'low')

      expect(inbox.messages.count).to eq(0)
      expect(import_jobs.map { |job| job['queue_name'] }).to eq([slots::WAITING_QUEUE])

      Redis::Alfred.with { |conn| conn.zrem(slots::KEY, tokens.first) }
      perform_enqueued_jobs(only: Whatsapp::Session::HistoryImportJob)
      expect(inbox.messages.count).to eq(100)
    end

    # Sidekiq retries a failed slice for weeks, and every deferred event of the inbox would
    # wait on it for a day. Only the chat lock's own retry keeps it pending.
    it 'stops holding the deferred events once its slice fails' do
      allow(Whatsapp::Session::Inbound::HistoryImporter).to receive(:new).and_raise(ActiveRecord::RecordNotSaved, 'invalid phone')

      dispatch(frame)
      job = import_jobs.first
      expect { ActiveJob::Base.execute(job) }.to raise_error(ActiveRecord::RecordNotSaved)

      expect(Whatsapp::Session::HistoryImportJob.pending?(inbox)).to be(false)
    end

    it 'stays pending while the chat lock sends it back to wait' do
      busy = Whatsapp::Session::Inbound::Locks::Busy.new('busy')
      allow(Whatsapp::Session::Inbound::HistoryImporter).to receive(:new).and_raise(busy)

      dispatch(frame)
      perform_enqueued_jobs(only: Whatsapp::Session::HistoryImportJob, queue: 'low')

      expect(Whatsapp::Session::HistoryImportJob.pending?(inbox)).to be(true)
    ensure
      Redis::Alfred.delete(Whatsapp::Session::HistoryImportJob.pending_key(inbox))
    end

    it 'stops holding them once the chat lock has had its last attempt' do
      allow(Whatsapp::Session::Inbound::HistoryImporter).to receive(:new).and_raise(Whatsapp::Session::Inbound::Locks::Busy)
      dispatch(frame)
      busy = [Whatsapp::Session::Inbound::Locks::Busy].to_s
      last = Whatsapp::Session::HistoryImportJob::BUSY_ATTEMPTS - 1
      job = import_jobs.first.merge('exception_executions' => { busy => last })

      expect { ActiveJob::Base.execute(job) }.to raise_error(Whatsapp::Session::Inbound::Locks::Busy)

      expect(Whatsapp::Session::HistoryImportJob.pending?(inbox)).to be(false)
    end
  end

  # WhatsApp's own account (0@s.whatsapp.net) files years of notices in the dump. It is
  # nobody to talk to, and its number, +0, is not one a contact can hold: every slice of it
  # failed on the phone validation, measured on a real pairing.
  describe "WhatsApp's own account" do
    before { channel.update!(provider_config: channel.provider_config.merge('history_sync' => true)) }

    it 'files nothing from it and queues nothing for it' do
      system = model::Address.phone('0')
      frame = slice([historical('3EB0SYS1', 2.days.ago, chat: system)], sync: 'full', chat: system)

      expect(dispatch(frame)).to eq(:ignored)

      expect(import_jobs).to be_empty
      expect(inbox.contacts.count).to eq(0)
    end
  end

  describe 'the end of the history' do
    # WhatsApp's answer to a request for a chat with nothing older is an empty slice that
    # says so, and the thread has to stop offering the button.
    it 'marks every thread of the chat, however the answer addresses it' do
      by_phone = threads_of(a_contact, phone, %i[resolved open])
      other_lid = '182736451928375'
      by_lid = threads_of(a_contact('5541999990001', identifier: "#{other_lid}@lid"), '5541999990001', %i[open])

      expect do
        expect(deliver(slice([], exhausted: true))).to eq(:handled)
        expect(deliver(slice([], chat: model::Address.lid(other_lid), exhausted: true))).to eq(:handled)
      end.not_to change(inbox.messages, :count)

      expect((by_phone + by_lid).map { |thread| exhausted?(thread) }).to eq([true, true, true])
    end

    it 'tells the thread somebody is reading, so the button goes without a reload' do
      thread = threads_of(a_contact, phone, %i[open]).first
      allow(ActionCableListener.instance).to receive(:conversation_updated)
      expect(EventDispatcherJob).not_to receive(:perform_later)

      deliver(slice([], exhausted: true))

      expect(ActionCableListener.instance).to have_received(:conversation_updated)
        .with(having_attributes(data: hash_including(conversation: thread, broadcast_metadata: { source: 'history_exhausted' })))
        .at_least(:once)
    end

    # A dump nobody asked for drops its archive, so it cannot also say the chat is done.
    it 'does not mark the chat from a dump whose archive was dropped' do
      thread = threads_of(a_contact, phone, %i[open]).first
      cover!(1.day.ago)

      deliver(slice([historical('3EB0UNASKED', 30.days.ago)], sync: 'full', exhausted: true))

      expect(inbox.messages.where(source_id: '3EB0UNASKED')).to be_empty
      expect(exhausted?(thread)).to be(false)
    end

    it 'marks only when the slice says so, and after its messages are filed' do
      thread = threads_of(a_contact, phone, %i[open]).first
      first = [0, 1, 2].map { |minute| historical("3EB0A#{minute}", 5.days.ago + minute.minutes) }
      last = [3, 4].map { |minute| historical("3EB0A#{minute}", 6.days.ago + minute.minutes) }

      deliver(slice(first))
      expect(exhausted?(thread)).to be(false)

      deliver(slice(last, exhausted: true))
      expect(inbox.messages.where(source_id: (first + last).map(&:id)).count).to eq(5)
      expect(exhausted?(thread)).to be(true)

      expect { deliver(slice(last, exhausted: true)) }.not_to change(inbox.messages, :count)
      expect(exhausted?(thread)).to be(true)
    end
  end

  # An edit that follows a slice on the stream can reach its target before the slice is
  # filed, and the slice can wait for a slot for as long as the dump ahead of it takes.
  describe 'an edit that overtakes its slice' do
    let(:edit) do
      payload = model::Events::MessageEdited.new(message_id: '3EB0OVER', chat: chat, timestamp: 1_755_440_000_000,
                                                 content: model::Content::Text.new(body: 'editada'))
      model::Event.build(payload, id: 'evt-7', sid: channel.provider_config['session_id'], epoch: 1, seq: 7, ts: 1, inst: 'c')
    end

    it 'waits while the slice is queued, without spending its retries, and applies once it is filed' do
      threads_of(a_contact, phone, %i[open])
      dispatch(slice([historical('3EB0OVER', 2.days.ago)]))

      freeze_time do
        expect { Whatsapp::Session::DeferredEventJob.perform_now(channel, edit.to_frame) }
          .to have_enqueued_job(Whatsapp::Session::DeferredEventJob).with(channel, edit.to_frame).at(1.minute.from_now)
      end

      perform_enqueued_jobs(only: Whatsapp::Session::HistoryImportJob)
      expect(Whatsapp::Session::HistoryImportJob.pending?(inbox)).to be(false)

      Whatsapp::Session::DeferredEventJob.perform_now(channel, edit.to_frame)
      expect(inbox.messages.find_by(source_id: '3EB0OVER').content).to eq('editada')
    ensure
      Redis::Alfred.delete(Whatsapp::Session::HistoryImportJob.pending_key(inbox))
    end
  end

  describe 'a slice that waited while the inbox moved on' do
    # A native inbox keeps its session id for good, so what moves it is a conversion to
    # another provider; written past the callbacks, which is all the job gets to see.
    it 'files nothing once the inbox has moved to another provider' do
      dispatch(slice([historical('3EB0MOVED', 2.days.ago)]))
      channel.update_columns(provider: 'uazapi', provider_config: { 'base_url' => 'https://uazapi.test', 'token' => 'x' }) # rubocop:disable Rails/SkipsModelValidations

      perform_enqueued_jobs(only: Whatsapp::Session::HistoryImportJob)

      expect(inbox.messages.where(source_id: '3EB0MOVED')).to be_empty
      expect(Whatsapp::Session::HistoryImportJob.pending?(inbox)).to be(false)
    end
  end

  describe 'a slice that waited while the inbox was re-pointed at another number' do
    it 'files nothing, though the session id stayed' do
      dispatch(slice([historical('3EB0OTHERNUM', 2.days.ago)]))
      channel.update_columns(phone_number: '+5541988887777') # rubocop:disable Rails/SkipsModelValidations

      perform_enqueued_jobs(only: Whatsapp::Session::HistoryImportJob)

      expect(inbox.messages.where(source_id: '3EB0OTHERNUM')).to be_empty
    end
  end

  describe 'what the setting decides' do
    it 'files only what arrived while the session was down when nobody asked' do
      watermark = 4.days.ago
      cover!(watermark)
      older = [1, 2, 3].map { |days| historical("3EB0OLD#{days}", watermark - days.days) }
      newer = [1, 2].map { |hours| historical("3EB0NEW#{hours}", watermark + hours.hours) }

      expect { deliver(slice(older + newer, sync: 'recent')) }.to change(inbox.messages, :count).by(2)

      expect(inbox.messages.where(source_id: older.map(&:id))).to be_empty
      expect(inbox.messages.where(source_id: newer.map(&:id)).map { |row| row.conversation.status }.uniq).to eq(['open'])
    end

    # A press on one chat opens a window for the whole inbox, and a pairing dump arriving
    # at the same time is not what was asked for: the connector says which slice answers.
    it 'keeps the dump volunteered while a request is pending out of the archive' do
      cover!(4.days.ago)
      Whatsapp::Session::HistoryBackfill.open!(channel)

      deliver(slice([historical('3EB0VOL', 10.days.ago)], sync: 'full'))

      expect(inbox.messages.where(source_id: '3EB0VOL')).to be_empty
    ensure
      Whatsapp::Session::HistoryBackfill.close!(channel)
    end

    # The phone pages back only from a message it dumped, so the newest one dropped is kept
    # as the anchor a later request for the chat starts from.
    it 'keeps where the dropped archive ended, to page back from later' do
      cover!(4.days.ago)
      dropped = [10, 8, 9].map { |days| historical("3EB0DROP#{days}", days.days.ago) }

      deliver(slice(dropped, sync: 'full'))

      expect(inbox.messages.where(source_id: dropped.map(&:id))).to be_empty
      anchor = Whatsapp::Session::HistoryAnchors.recall(inbox, [chat])
      expect(anchor).to have_attributes(id: '3EB0DROP8', timestamp: dropped[1].timestamp, from_me: false)
    end

    it 'keeps the newest dropped message whatever order the slices arrive in' do
      cover!(4.days.ago)

      deliver(slice([historical('3EB0LATER', 8.days.ago)], sync: 'full'))
      deliver(slice([historical('3EB0EARLIER', 20.days.ago)], sync: 'full'))

      expect(Whatsapp::Session::HistoryAnchors.recall(inbox, [chat]).id).to eq('3EB0LATER')
    end

    it 'archives the dump in silence when the setting is on' do
      channel.update!(provider_config: channel.provider_config.merge('history_sync' => true))
      cover!(1.day.ago)
      dump = [3, 1, 5, 2, 4].map { |days| historical("3EB0ARC#{days}", (days + 1).days.ago) }

      expect { deliver(slice(dump, sync: 'bootstrap')) }.not_to change(Notification, :count)

      rows = inbox.messages.where(source_id: dump.map(&:id)).order(:created_at)
      expect(rows.map(&:conversation_id).uniq.size).to eq(1)
      expect(rows.first.conversation.status).to eq('resolved')
      expect(rows.map(&:source_id)).to eq(dump.sort_by(&:timestamp).map(&:id))
      rows.each do |row|
        sent = dump.find { |item| item.id == row.source_id }.timestamp / 1000.0
        expect(row.created_at).to be_within(1.second).of(Time.zone.at(sent))
      end
    end
  end

  describe 'who sees it land' do
    before do
      channel.update!(provider_config: channel.provider_config.merge('history_sync' => true))
      cover!(1.day.ago)
      threads_of(a_contact, phone, %i[open])
      allow(ActionCableListener.instance).to receive(:message_created)
    end

    it 'announces the answer somebody asked for from a thread' do
      deliver(slice([3, 4, 5].map { |days| historical("3EB0ASK#{days}", days.days.ago) }))

      expect(ActionCableListener.instance).to have_received(:message_created).at_least(:once)
      expect(inbox.messages.where(source_id: %w[3EB0ASK3 3EB0ASK4 3EB0ASK5]).count).to eq(3)
    end

    it 'files the answer as history even while announcing it' do
      levels = []
      allow(Whatsapp::Session::Inbound::MessageWriter).to receive(:new).and_wrap_original do |original, **kwargs|
        levels << [Import::SilentWrite.announce?, Import::SilentWrite.archive?]
        original.call(**kwargs)
      end

      deliver(slice([3, 4].map { |days| historical("3EB0LVL#{days}", days.days.ago) }))

      expect(levels).to eq([[true, true], [true, true]])
    end

    # The dashboard shows it, and it still says it is archive, so no alert sounds for it.
    it 'marks the answer as archive and the gap as not' do
      deliver(slice([historical('3EB0OLDPAGE', 3.days.ago), historical('3EB0FRESH', 1.hour.ago)]))

      expect(inbox.messages.find_by(source_id: '3EB0OLDPAGE').content_attributes['history_archive']).to be(true)
      expect(inbox.messages.find_by(source_id: '3EB0FRESH').content_attributes['history_archive']).to be_nil
    end

    it 'files the full dump without a word to the dashboard' do
      deliver(slice([3, 4, 5].map { |days| historical("3EB0FUL#{days}", days.days.ago) }, sync: 'full'))

      expect(ActionCableListener.instance).not_to have_received(:message_created)
      expect(inbox.messages.where(source_id: %w[3EB0FUL3 3EB0FUL4 3EB0FUL5]).count).to eq(3)
    end
  end

  # The dashboard walks a contact's threads by creation date, so history is filed in the
  # thread that was current when it happened, not in whichever one is newest when it
  # arrives: pressing the button on different days used to scatter one chat's past across
  # them out of order.
  describe 'which thread the archive lands in' do
    let(:contact) { a_contact }
    let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: phone) }
    let(:first_thread) { thread_opened(10.days.ago) }
    let(:second_thread) { thread_opened(5.days.ago) }
    let(:latest_thread) { thread_opened(1.day.ago, status: :open) }

    before do
      channel.update!(provider_config: channel.provider_config.merge('history_sync' => true))
      [first_thread, second_thread, latest_thread]
    end

    def thread_opened(at, status: :resolved)
      conversation = create(:conversation, inbox: inbox, account: inbox.account, contact: contact, contact_inbox: contact_inbox,
                                           status: status, created_at: at)
      create(:message, conversation: conversation, inbox: inbox, account: inbox.account, source_id: "LIVE#{SecureRandom.hex(4)}",
                       created_at: at)
      conversation
    end

    def filed_in(*ids) = inbox.messages.where(source_id: ids).map(&:conversation).uniq

    it 'files what predates every thread in the oldest one, however new the latest is' do
      deliver(slice([40, 20].map { |days| historical("3EB0PAST#{days}", days.days.ago) }))

      expect(filed_in('3EB0PAST40', '3EB0PAST20')).to eq([first_thread])
    end

    it 'splits one slice across the threads that were current when each message was sent' do
      deliver(slice([20, 8, 7, 3, 2].map { |days| historical("3EB0SPAN#{days}", days.days.ago) }))

      expect(filed_in('3EB0SPAN20', '3EB0SPAN8', '3EB0SPAN7')).to eq([first_thread])
      expect(filed_in('3EB0SPAN3', '3EB0SPAN2')).to eq([second_thread])
      expect(latest_thread.messages.count).to eq(1)
    end

    # The lock means one thread for the contact, history included: by date it would go to
    # threads from before the lock was turned on.
    it 'files everything in the last thread on an inbox locked to one conversation' do
      inbox.update!(lock_to_single_conversation: true)

      deliver(slice([40, 7].map { |days| historical("3EB0LOCK#{days}", days.days.ago) }))

      expect(filed_in('3EB0LOCK40', '3EB0LOCK7')).to eq([latest_thread])
    end

    # The lock picks the highest id, and a thread a gap import opened is dated back, so the
    # pick can be older by date than another thread: the run still lands whole in it.
    it 'files a locked inbox in its last thread even when ids and dates disagree' do
      inbox.update!(lock_to_single_conversation: true)
      backdated = thread_opened(20.days.ago)

      deliver(slice([3, 2].map { |days| historical("3EB0BACK#{days}", days.days.ago) }))

      expect(filed_in('3EB0BACK3', '3EB0BACK2')).to eq([backdated])
    end
  end

  describe 'the name of a group' do
    let(:unnamed) { model::Address.group('120363400000000001') }
    let(:named) { model::Address.group('120363400000000002') }

    around { |example| with_modified_env(WHATSAPP_GROUPS_ENABLED: 'true') { example.run } }

    before do
      channel.update!(provider_config: channel.provider_config.merge('history_sync' => true))
      { unnamed => unnamed.id, named => 'Nome Antigo' }.each do |group, name|
        contact = create(:contact, account: inbox.account, name: name, identifier: group.to_jid, group_type: :group)
        create(:contact_inbox, contact: contact, inbox: inbox, source_id: group.id)
      end
      allow(Contacts::SyncGroupJob).to receive(:perform_later)
    end

    def group_slice(group, name, ids)
      slice(ids.each_with_index.map { |id, days| historical(id, (days + 1).days.ago, chat: group) }, chat: group, name: name)
    end

    it 'leaves alone a group another inbox of the account already named' do
      elsewhere = model::Address.group('120363400000000003')
      contact = create(:contact, account: inbox.account, name: 'Nome de Outra Inbox', identifier: elsewhere.to_jid, group_type: :group)
      create(:contact_inbox, contact: contact, inbox: create(:inbox, account: inbox.account), source_id: elsewhere.id)

      deliver(group_slice(elsewhere, 'Nome do Dump', %w[3EB0G31]))

      expect(contact.reload.name).to eq('Nome de Outra Inbox')
    end

    it 'names a group filed under its own id, and leaves a named one alone' do
      deliver(group_slice(unnamed, 'Grupo WAC 407', %w[3EB0G11 3EB0G12]))
      deliver(group_slice(named, 'Outro Nome', %w[3EB0G21 3EB0G22]))

      expect(inbox.contact_inboxes.find_by(source_id: unnamed.id).contact.name).to eq('Grupo WAC 407')
      expect(inbox.contact_inboxes.find_by(source_id: named.id).contact.name).to eq('Nome Antigo')
      expect(inbox.messages.where(source_id: %w[3EB0G11 3EB0G12 3EB0G21 3EB0G22]).count).to eq(4)
    end
  end

  # The connector publishes a slice's media without a reference to its bytes, and nothing
  # follows it the way `media.download_failed` follows a live message.
  describe 'media in a slice' do
    let(:picture) { model::Content::Media.new(kind: 'image', mime: 'image/jpeg') }
    let(:messages) do
      [historical('3EB0M1', 3.days.ago), historical('3EB0M2', 3.days.ago + 1.minute, content: picture),
       historical('3EB0M3', 3.days.ago + 2.minutes)]
    end

    before { threads_of(a_contact, phone, %i[open]) }

    it 'files the picture as an unsupported bubble in its place, and fetches nothing' do
      deliver(slice(messages))

      rows = inbox.messages.where(source_id: %w[3EB0M1 3EB0M2 3EB0M3]).order(:created_at)
      expect(rows.map(&:source_id)).to eq(%w[3EB0M1 3EB0M2 3EB0M3])
      image = rows.second
      expect(image).to be_incoming
      expect(image.created_at).to be_within(1.second).of(3.days.ago + 1.minute)
      expect(image.content_attributes['is_unsupported']).to be(true)
      expect(image.attachments).to be_empty
      expect(enqueued_jobs.map { |job| job['job_class'] }).not_to include('Whatsapp::Session::MediaFetchJob')
    end

    # A card is still readable without its header, so it stays a card.
    it 'keeps a card with text readable when only its header picture is missing' do
      card = model::Content::Rich.new(kind: 'button', title: 'Pedido #4312', body: 'Seu pedido saiu para entrega',
                                      media: model::Content::Media.new(kind: 'image', mime: 'image/jpeg'))

      deliver(slice([historical('3EB0CARD', 2.days.ago, content: card)]))

      # Still a card, and its header still waits for the drain like any other history file.
      message = inbox.messages.find_by(source_id: '3EB0CARD')
      expect(message.content_attributes['is_unsupported']).to be_nil
      expect(Whatsapp::Session::HistoryMedia.pending?(message)).to be(true)
    ensure
      Redis::Alfred.delete(Whatsapp::Session::HistoryMedia.queue_key(inbox))
      Redis::Alfred.delete(Whatsapp::Session::HistoryMediaJob.scheduled_key(inbox))
    end

    # The same card with a reference to its header: the header waits for the drain, and
    # the card keeps rendering as a card meanwhile.
    it 'keeps a card with text readable while its referenced header waits for the drain' do
      ref = model::MediaRef.new(kind: 'url', url: 'https://connector.test/media/card', mime: 'image/jpeg')
      card = model::Content::Rich.new(kind: 'button', title: 'Pedido #4312', body: 'Seu pedido saiu para entrega',
                                      media: model::Content::Media.new(kind: 'image', mime: 'image/jpeg', ref: ref))

      deliver(slice([historical('3EB0CARD2', 2.days.ago, content: card)]))

      message = inbox.messages.find_by(source_id: '3EB0CARD2')
      expect(message.content_attributes['is_unsupported']).to be_nil
      expect(Whatsapp::Session::HistoryMedia.pending?(message)).to be(true)
    ensure
      Redis::Alfred.delete(Whatsapp::Session::HistoryMedia.queue_key(inbox))
      Redis::Alfred.delete(Whatsapp::Session::HistoryMediaJob.scheduled_key(inbox))
    end

    # A caption edit is not the file: the bubble has to keep saying the file is missing.
    it 'keeps the picture marked missing after its caption is edited' do
      deliver(slice(messages))
      edit = model::Event.build(model::Events::MessageEdited.new(message_id: '3EB0M2', chat: chat, timestamp: 1_755_440_000_000,
                                                                 content: model::Content::Text.new(body: 'legenda nova')))

      Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, edit)

      expect(inbox.messages.find_by(source_id: '3EB0M2').content_attributes['is_unsupported']).to be(true)
    end

    # The same message delivered again with its reference, which a dump that overlaps the
    # live stream does: the placeholder is waiting for exactly that.
    it 'fetches the file when the message comes again with its reference' do
      deliver(slice(messages))
      image = inbox.messages.find_by(source_id: '3EB0M2')
      ref = model::MediaRef.new(kind: 'url', url: 'https://connector.test/media/abc', mime: 'image/jpeg')
      again = historical('3EB0M2', 3.days.ago + 1.minute, content: model::Content::Media.new(kind: 'image', mime: 'image/jpeg', ref: ref))

      # Through the inbox's drain, which reads the switch and the window before asking,
      # with the reference this delivery brought kept for the ask.
      expect { Whatsapp::Session::Inbound::MessageWriter.fetch_media_for(image, again) }
        .not_to have_enqueued_job(Whatsapp::Session::MediaFetchJob)
      queued = Redis::Alfred.zrangebyscore(Whatsapp::Session::HistoryMedia.queue_key(inbox), '-inf', '+inf')
      expect(queued).to eq([image.id.to_s])
      expect(image.reload.content_attributes.dig('pending_media', 'ref', 'url')).to eq('https://connector.test/media/abc')
    ensure
      Redis::Alfred.delete(Whatsapp::Session::HistoryMedia.queue_key(inbox))
      Redis::Alfred.delete(Whatsapp::Session::HistoryMediaJob.scheduled_key(inbox))
    end

    it 'asks for nothing on a redelivery once the inbox turned the automatic fetch off' do
      channel.update!(provider_config: channel.provider_config.merge('history_media_fetch' => false))
      deliver(slice(messages))
      image = inbox.messages.find_by(source_id: '3EB0M2')
      ref = model::MediaRef.new(kind: 'url', url: 'https://connector.test/media/abc', mime: 'image/jpeg')
      again = historical('3EB0M2', 3.days.ago + 1.minute, content: model::Content::Media.new(kind: 'image', mime: 'image/jpeg', ref: ref))

      expect { Whatsapp::Session::Inbound::MessageWriter.fetch_media_for(image, again) }
        .not_to have_enqueued_job(Whatsapp::Session::MediaFetchJob)
      expect(Redis::Alfred.zcard(Whatsapp::Session::HistoryMedia.queue_key(inbox))).to eq(0)
      expect(Whatsapp::Session::HistoryMedia.pending?(image.reload)).to be(true)
    ensure
      Redis::Alfred.delete(Whatsapp::Session::HistoryMedia.queue_key(inbox))
      Redis::Alfred.delete(Whatsapp::Session::HistoryMediaJob.scheduled_key(inbox))
    end
  end

  # A provider whose history does carry the file's reference (uazapi) still gets it fetched,
  # through the inbox's drain like any other history file, reference and all.
  it 'queues an imported file that can still be fetched, keeping its reference' do
    threads_of(a_contact, phone, %i[open])
    ref = model::MediaRef.new(kind: 'url', url: 'https://connector.test/media/abc', mime: 'image/jpeg')
    fetchable = historical('3EB0REF', 1.day.ago, content: model::Content::Media.new(kind: 'image', mime: 'image/jpeg', ref: ref))

    deliver(slice([fetchable]))

    message = inbox.messages.find_by(source_id: '3EB0REF')
    queue = Whatsapp::Session::HistoryMedia.queue_key(inbox)
    expect(Redis::Alfred.zrangebyscore(queue, '-inf', '+inf')).to eq([message.id.to_s])
    expect(message.content_attributes.dig('pending_media', 'ref', 'url')).to eq('https://connector.test/media/abc')
  ensure
    Redis::Alfred.delete(Whatsapp::Session::HistoryMedia.queue_key(inbox))
    Redis::Alfred.delete(Whatsapp::Session::HistoryMediaJob.scheduled_key(inbox))
  end

  # The boundary is read once, when the slice is read, and handed to the job: slices of one
  # dump run in parallel, and one reading it for itself would measure against what the
  # others had already written.
  it 'files a slice against the boundary read when it arrived, not when its job ran' do
    cover!(1.day.ago)
    dispatch(slice([historical('3EB0HALF', 12.hours.ago)], sync: 'recent'))
    cover!(1.minute.ago)

    perform_enqueued_jobs(only: Whatsapp::Session::HistoryImportJob)

    expect(inbox.messages.find_by(source_id: '3EB0HALF').conversation.status).to eq('open')
  end

  describe 'the same message twice' do
    it 'files each id once, whether it repeats inside the slice, across deliveries, or was stored live' do
      live = threads_of(a_contact, phone, %i[open]).first
      create(:message, conversation: live, inbox: inbox, account: inbox.account, source_id: '3EB0LIVE', created_at: 1.hour.ago)
      fresh = Array.new(97) { |index| historical(format('3EB0D%03d', index), (300 - index).minutes.ago) }
      frame = slice([historical('3EB0LIVE', 1.hour.ago)] + fresh + [fresh[10]])

      expect { deliver(frame) }.to change(inbox.messages, :count).by(97)
      expect { deliver(frame) }.not_to change(inbox.messages, :count)
      expect(inbox.messages.reorder(nil).group(:source_id).having('count(*) > 1').count).to be_empty
    end
  end

  # The live rule (#793): what a blocked contact sends is not filed, and the echo of a reply
  # typed on the phone is, so the agent's own answer does not go missing.
  describe 'a blocked contact' do
    let(:echo) do
      model::InboundMessage.new(
        id: '3EB0OUT', chat: chat, sender: sender, from_me: true, timestamp: (1.day.ago.to_f * 1000).to_i,
        content: model::Content::Text.new(body: 'resposta')
      )
    end

    before { threads_of(a_contact(blocked: true), phone, []) }

    it 'files only the echoes' do
      deliver(slice([historical('3EB0IN', 2.days.ago), echo]))

      expect(inbox.messages.pluck(:source_id)).to eq(['3EB0OUT'])
    end

    it 'leaves no thread behind when the contact is all the slice has' do
      deliver(slice([historical('3EB0IN', 2.days.ago)]))

      expect(inbox.conversations).to be_empty
    end
  end
end
