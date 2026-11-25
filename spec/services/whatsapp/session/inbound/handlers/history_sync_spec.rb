require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::HistorySync do
  # The handler queues each slice and the job files it, so both run here: what is asserted
  # is where the messages end up.
  subject(:dispatch) { deliver(event) }

  def deliver(frame)
    perform_enqueued_jobs(only: Whatsapp::Session::HistoryImportJob) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, frame) }
  end

  after { Redis::Alfred.delete(Whatsapp::Session::Inbound::ImportSlots::KEY) }

  let(:channel) do
    create(:channel_whatsapp, provider: 'uazapi', validate_provider_config: false, sync_templates: false,
                              provider_config: { 'base_url' => 'https://uazapi.test', 'token' => 'x', 'history_sync' => true })
  end
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:chat) { model::Address.phone('5541999990000') }
  let(:sender) { model::Party.new(phone: '5541999990000', lid: '182736451928374', push_name: 'Ana Souza') }

  # Coverage: an unrelated chat this inbox received four days ago. It is what makes the
  # boundary exist at all, and keeping it on another contact leaves the chat under test
  # untouched by it.
  let(:covered_until) { 4.days.ago }

  let(:event) { model::Event.build(model::Events::HistorySync.new(kind: 'messages', data: { 'messages' => messages.map(&:to_h) })) }
  let(:messages) { [historical(id: 'HIST01', at: 2.years.ago, body: 'orçamento de junho')] }

  def historical(id:, at:, body:, from_me: false)
    model::InboundMessage.new(
      id: id, chat: chat, sender: (sender unless from_me), from_me: from_me,
      timestamp: (at.to_f * 1000).to_i, content: model::Content::Text.new(body: body)
    )
  end

  def cover!
    conversation = create(:conversation, inbox: inbox, account: inbox.account)
    create(:message, conversation: conversation, inbox: inbox, source_id: 'LIVE01', created_at: covered_until)
  end

  describe 'the archive half' do
    before { cover! }

    it 'files the message in a conversation that is resolved from the start' do
      expect(dispatch).to eq(:handled)

      conversation = inbox.messages.find_by(source_id: 'HIST01').conversation
      expect(conversation.status).to eq('resolved')
    end

    # Resolved on create rather than resolved afterwards. `notify_status_change` and
    # `create_activity` are after_update callbacks, so a thread born resolved writes no
    # "resolved by" line and reports no resolution: an import of five hundred threads
    # would otherwise land in today's figures as five hundred resolutions.
    it 'writes no activity message into the imported thread' do
      dispatch

      conversation = inbox.messages.find_by(source_id: 'HIST01').conversation
      expect(conversation.messages.where(message_type: :activity)).to be_empty
    end

    it 'dates the message and the thread to when it happened' do
      dispatch

      message = inbox.messages.find_by(source_id: 'HIST01')
      expect(message.created_at).to be_within(1.second).of(2.years.ago)
      expect(message.conversation.created_at).to be_within(1.second).of(2.years.ago)
      expect(message.content_attributes['imported']).to be(true)
    end

    # A thread is born stamped as active now, and the inbox sorts on that column: without
    # correcting it, importing an archive would put every thread from 2024 above this
    # morning's conversations.
    it 'does not put a two-year-old thread at the top of the inbox' do
      dispatch

      conversation = inbox.messages.find_by(source_id: 'HIST01').conversation
      expect(conversation.last_activity_at).to be_within(1.second).of(2.years.ago)
    end

    it 'does not tell WhatsApp the message was received' do
      expect_any_instance_of(Whatsapp::Session::Facade).not_to receive(:received_messages) # rubocop:disable RSpec/AnyInstance

      dispatch
    end

    # Nothing at all, the dashboard included. The archive is backfill: a reader has
    # nothing to gain from eight hundred backdated threads arriving one cable frame at a
    # time, and every agent in the account would get the flood.
    it 'sets off no listener, the dashboard push included' do
      expect(ActionCableListener.instance).not_to receive(:conversation_updated)
      expect(ActionCableListener.instance).not_to receive(:message_created)
      expect(AgentBotListener.instance).not_to receive(:conversation_updated)
      expect(EventDispatcherJob).not_to receive(:perform_later)

      dispatch
    end

    context 'when the contact already has a resolved thread' do
      let!(:existing) do
        contact = create(:contact, account: inbox.account, phone_number: '+5541999990000')
        contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox, source_id: '5541999990000')
        create(:conversation, inbox: inbox, account: inbox.account, contact: contact, contact_inbox: contact_inbox,
                              status: :resolved)
      end

      it 'lands in it instead of opening work' do
        dispatch

        expect(inbox.messages.find_by(source_id: 'HIST01').conversation).to eq(existing)
        expect(existing.reload.status).to eq('resolved')
      end

      # `set_conversation_activity` assigns whatever row it has just written. Left to run
      # over history it would drag the thread's last activity back two years, and an inbox
      # sorted by activity would show a conversation answered this morning as untouched.
      it 'does not drag the thread activity backwards' do
        existing.update!(last_activity_at: 1.hour.ago)

        expect { dispatch }.not_to(change { existing.reload.last_activity_at.to_i })
      end
    end

    context 'with a batch for one chat' do
      let(:messages) do
        [
          historical(id: 'HIST01', at: 2.years.ago, body: 'primeira'),
          historical(id: 'HIST02', at: 1.year.ago, body: 'segunda'),
          historical(id: 'HIST03', at: 6.months.ago, body: 'terceira')
        ]
      end

      it 'keeps the whole chat in one conversation' do
        dispatch

        expect(inbox.conversations.count).to eq(2) # the covering thread, and this one
        expect(inbox.messages.where(source_id: %w[HIST01 HIST02 HIST03]).map(&:conversation_id).uniq.size).to eq(1)
      end
    end

    it 'is idempotent' do
      dispatch

      expect { deliver(event) }.not_to change(inbox.messages, :count)
    end
  end

  # A dump carries its files without a reference, so each one waits in the inbox's history
  # queue, under the chat the event named, to be asked for by message id.
  describe 'the files of the archive' do
    before { cover! }

    let(:queue) { Whatsapp::Session::HistoryMedia.queue_key(inbox) }
    let(:messages) { [photo(id: 'HIST10', at: 3.days.ago), photo(id: 'HIST11', at: 90.days.ago)] }

    after do
      Redis::Alfred.delete(queue)
      Redis::Alfred.delete(Whatsapp::Session::HistoryMediaJob.scheduled_key(inbox))
    end

    def photo(id:, at:)
      model::InboundMessage.new(
        id: id, chat: chat, sender: sender, from_me: false, timestamp: (at.to_f * 1000).to_i,
        content: model::Content::Media.new(kind: 'image', mime: 'image/jpeg', filename: 'foto.jpg')
      )
    end

    it 'queues the files inside the window and keeps the chat each was filed under' do
      dispatch

      recent = inbox.messages.find_by(source_id: 'HIST10')
      expect(recent.content_attributes['pending_chat']).to eq(chat.to_h)
      queued = Redis::Alfred.zrangebyscore(queue, '-inf', '+inf')
      expect(queued).to eq([recent.id.to_s])
      expect(Whatsapp::Session::HistoryMediaJob).to have_been_enqueued.with(inbox).exactly(:once)
    end

    # The batch wrote the row and failed before queuing its file (Redis went away), so its
    # retry finds the row stored and would skip it for good.
    it 'queues again a stored file a retried batch would skip' do
      dispatch
      Redis::Alfred.delete(queue)
      Redis::Alfred.delete(Whatsapp::Session::HistoryMediaJob.scheduled_key(inbox))

      deliver(event)

      expect(Redis::Alfred.zrangebyscore(queue, '-inf', '+inf')).to eq([inbox.messages.find_by(source_id: 'HIST10').id.to_s])
    end

    # The slice is written oldest first: a drain started halfway would take the newest of
    # what is written so far before the newest of the slice.
    context 'with several files inside the window' do
      let(:messages) { [photo(id: 'HIST20', at: 3.days.ago), photo(id: 'HIST21', at: 2.days.ago)] }

      it 'starts the drain only once the whole slice is written' do
        written = nil
        allow(Whatsapp::Session::HistoryMediaJob).to receive(:set).and_wrap_original do |original, *args, **options|
          written ||= inbox.messages.where(source_id: %w[HIST20 HIST21]).count
          original.call(*args, **options)
        end

        dispatch

        expect(written).to eq(2)
      end
    end

    # A file left waiting by an import from before the drain existed, or queued when nothing
    # could run it: the next slice is what comes back for it, whatever that slice carries.
    it 'asks for the files already waiting in the inbox once a slice is in, at most every few minutes' do
      rescanned = "WHATSAPP::HISTORY_MEDIA_RESCANNED::#{inbox.id}"
      requeue = Whatsapp::Session::HistoryMediaJob.requeue_key(inbox)
      Redis::Alfred.delete(rescanned)

      dispatch
      expect(Redis::Alfred.exists?(requeue)).to be(true)

      Redis::Alfred.delete(requeue)
      deliver(model::Event.build(model::Events::HistorySync.new(kind: 'messages', data: { 'messages' => [photo(id: 'HIST12', at: 1.day.ago).to_h] })))
      expect(Redis::Alfred.exists?(requeue)).to be(false)
    ensure
      Redis::Alfred.delete(rescanned)
      Redis::Alfred.delete(requeue)
    end

    it 'queues nothing when the inbox turned the automatic fetch off' do
      channel.update!(provider_config: channel.provider_config.merge('history_media_fetch' => false))

      dispatch

      expect(inbox.messages.find_by(source_id: 'HIST10').content_attributes['history_media']).to be(true)
      expect(Redis::Alfred.zcard(queue)).to eq(0)
      expect(Whatsapp::Session::HistoryMediaJob).not_to have_been_enqueued
    end

    # A provider that hands the dump over with references (uazapi does) is held to the same
    # switch and window: turning the option off must not download the archive anyway.
    it 'holds files that came with a reference to the same switch and window' do
      referenced = lambda do |id, at|
        model::InboundMessage.new(
          id: id, chat: chat, sender: sender, from_me: false, timestamp: (at.to_f * 1000).to_i,
          content: model::Content::Media.new(kind: 'image', mime: 'image/jpeg', filename: 'foto.jpg',
                                             ref: model::MediaRef.url('https://uazapi.test/media/x'))
        )
      end
      channel.update!(provider_config: channel.provider_config.merge('history_media_days' => 7))
      deliver(model::Event.build(model::Events::HistorySync.new(
                                   kind: 'messages',
                                   data: { 'messages' => [referenced.call('REF1', 2.days.ago), referenced.call('REF2', 30.days.ago)].map(&:to_h) }
                                 )))
      expect(Whatsapp::Session::MediaFetchJob).not_to have_been_enqueued
      # The one inside the window goes to the drain, which reads the settings again before
      # downloading it; the one outside waits for the button or the conversation action.
      # Both keep the reference the provider finds the file by.
      inside = inbox.messages.find_by(source_id: 'REF1')
      deferred = inbox.messages.find_by(source_id: 'REF2')
      expect(Redis::Alfred.zrangebyscore(queue, '-inf', '+inf')).to eq([inside.id.to_s])
      expect(Whatsapp::Session::HistoryMedia.pending?(deferred)).to be(true)
      expect([inside, deferred].map { |message| message.content_attributes.dig('pending_media', 'ref') }).to all(be_present)

      channel.update!(provider_config: channel.provider_config.merge('history_media_fetch' => false))
      deliver(model::Event.build(model::Events::HistorySync.new(kind: 'messages',
                                                                data: { 'messages' => [referenced.call('REF3', 1.day.ago).to_h] })))
      expect(Redis::Alfred.zcard(queue)).to eq(1)
    end

    it 'measures the window the inbox chose' do
      channel.update!(provider_config: channel.provider_config.merge('history_media_days' => 120))

      dispatch

      expect(Redis::Alfred.zcard(queue)).to eq(2)
    end
  end

  describe 'the gap half' do
    before { cover! }

    let(:messages) { [historical(id: 'GAP01', at: 2.days.ago, body: 'bom dia, ainda preciso do orçamento')] }

    it 'opens the conversation, because nobody has had the chance to read it' do
      dispatch

      conversation = inbox.messages.find_by(source_id: 'GAP01').conversation
      expect(conversation.status).to eq('open')
      expect(conversation.waiting_since).to be_within(1.second).of(2.days.ago)
    end

    # The half somebody is waiting for, so the queue has to move without a reload: a gap
    # thread that lands behind a stale list is a thread nobody works. That is the whole of
    # the exception, though. A bot must not answer it and nothing may act on the world,
    # which is what the async side carries.
    it 'refreshes the dashboard and still sets off nothing else' do
      # Both halves of the screen: the card in the list, and the thread somebody has open.
      # Without the second, a reader watching the conversation sees the list say there is a
      # new message and the conversation stay empty underneath it.
      expect(ActionCableListener.instance).to receive(:conversation_updated).at_least(:once)
      expect(ActionCableListener.instance).to receive(:message_created).at_least(:once)
      expect(AgentBotListener.instance).not_to receive(:message_created)
      expect(AgentBotListener.instance).not_to receive(:conversation_updated)
      expect(EventDispatcherJob).not_to receive(:perform_later)

      dispatch
    end

    context 'when the contact answered on the phone during the outage' do
      let(:messages) do
        [
          historical(id: 'GAP01', at: 2.days.ago, body: 'bom dia'),
          historical(id: 'GAP02', at: 2.days.ago + 1.hour, body: 'já respondo', from_me: true)
        ]
      end

      it 'leaves no waiting clock running' do
        dispatch

        expect(inbox.messages.find_by(source_id: 'GAP01').conversation.waiting_since).to be_nil
      end
    end
  end

  # No coverage at all means a first connection, and the whole dump is history: an inbox
  # paired this morning must not open a year of threads on its way up.
  describe 'a first connection' do
    let(:messages) { [historical(id: 'HIST01', at: 10.minutes.ago, body: 'oi')] }

    it 'archives even what happened minutes ago' do
      dispatch

      expect(inbox.messages.find_by(source_id: 'HIST01').conversation.status).to eq('resolved')
    end
  end

  # Pointed at another instance of the same provider while the slice waited: the provider
  # did not change, the account behind the inbox did.
  it 'files nothing once the inbox points at another instance' do
    perform_enqueued_jobs(only: []) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) }
    channel.update_columns(provider_config: channel.provider_config.merge('token' => 'another')) # rubocop:disable Rails/SkipsModelValidations

    perform_enqueued_jobs(only: Whatsapp::Session::HistoryImportJob)

    expect(inbox.messages).to be_empty
  end

  describe 'what it refuses' do
    it 'ignores a kind it does not import' do
      chats = model::Event.build(model::Events::HistorySync.new(kind: 'chats', data: { 'chats' => [] }))

      expect(Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, chats)).to eq(:ignored)
    end

    # A history frame says nothing about why it came, and the phone dumps what it has at
    # every pairing. On an inbox with no coverage there is no gap by definition, so the
    # whole pile is archive and none of it is filed: setting a number up on Monday must not
    # fill it with a year of somebody's private conversations.
    it 'files nothing from an unrequested dump on an inbox with no coverage' do
      channel.update!(provider_config: channel.provider_config.merge('history_sync' => false))

      dispatch

      expect(inbox.messages).to be_empty
    end

    # The case the outright refusal used to destroy. Nobody asked, but the session was down
    # and came back, and what the phone is offering includes the only copy of what arrived
    # meanwhile. WhatsApp has no request that fetches it later, so this frame is the one
    # chance to keep it.
    context 'when an unrequested dump straddles the coverage boundary' do
      before do
        channel.update!(provider_config: channel.provider_config.merge('history_sync' => false))
        cover!
      end

      let(:messages) do
        [
          historical(id: 'OLD01', at: 2.years.ago, body: 'orçamento de junho'),
          historical(id: 'GAP99', at: 2.days.ago, body: 'chegou no fim de semana')
        ]
      end

      it 'keeps what arrived while the session was down' do
        dispatch

        gap = inbox.messages.find_by(source_id: 'GAP99')
        expect(gap).to be_present
        expect(gap.conversation.status).to eq('open')
      end

      it 'drops the archive half, which nobody asked for' do
        dispatch

        expect(inbox.messages.find_by(source_id: 'OLD01')).to be_nil
      end
    end

    # The other half of that: the button was pressed, so this was asked for, and it must
    # not need the connect-time setting to be honoured.
    it 'imports inside an open backfill window with the setting off' do
      channel.update!(provider_config: channel.provider_config.merge('history_sync' => false))
      Whatsapp::Session::HistoryBackfill.open!(channel)

      expect(dispatch).to eq(:handled)
      expect(inbox.messages.find_by(source_id: 'HIST01')).to be_present
    end

    it 'ignores history on a provider that does not declare the capability' do
      allow(channel).to receive(:session_capabilities).and_return(%w[groups media_download])

      expect(dispatch).to eq(:ignored)
      expect(inbox.messages).to be_empty
    end
  end
end
