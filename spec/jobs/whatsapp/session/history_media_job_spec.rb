require 'rails_helper'

RSpec.describe Whatsapp::Session::HistoryMediaJob do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }
  let(:conversation) { create(:conversation, inbox: inbox, account: channel.account) }
  let(:chat) { Whatsapp::Session::Model::Address.group('120363000000000001') }
  let(:queue) { Whatsapp::Session::HistoryMedia.queue_key(inbox) }

  before { allow(Whatsapp::Session::Registry).to receive(:backend_for).and_return(backend) }

  after do
    Redis::Alfred.delete(queue)
    Redis::Alfred.delete(described_class.scheduled_key(inbox))
    Redis::Alfred.delete(described_class.requeue_key(inbox))
    Redis::Alfred.delete(described_class.run_key(inbox))
    Redis::Alfred.delete("WHATSAPP::HISTORY_MEDIA_REQUEUE_CURSOR::#{inbox.id}")
  end

  def pending(source_id, at)
    create(:message, conversation: conversation, inbox: inbox, account: channel.account, source_id: source_id, created_at: at,
                     content_attributes: { 'is_unsupported' => true, 'history_media' => true, 'imported' => true,
                                           'pending_media' => Whatsapp::Session::Model::Content::Media.new(kind: 'image', mime: 'image/jpeg').to_h,
                                           'pending_chat' => chat.to_h })
  end

  def queue_up(*messages)
    messages.each { |message| Redis::Alfred.zadd(queue, message.created_at.to_f, message.id) }
  end

  it 'attaches the files newest first, asking under the chat the history named' do
    older = pending('OLD1', 10.days.ago)
    newer = pending('NEW1', 1.day.ago)
    queue_up(older, newer)

    described_class.perform_now(inbox)

    expect(backend.commands.map(&:message_id)).to eq(%w[NEW1 OLD1])
    expect(backend.commands.map { |command| command.chat.to_jid }.uniq).to eq([chat.to_jid])
    expect([older.reload, newer.reload].map { |message| message.attachments.count }).to eq([1, 1])
    expect(newer.content_attributes).not_to include('history_media', 'is_unsupported')
  end

  # Thousands of files must not hold one worker for hours, nor sit on the queue at once.
  it 'hands the queue back after a batch and comes back for the rest' do
    queue_up(*Array.new(described_class::BATCH + 2) { |index| pending("M#{index}", index.hours.ago) })

    described_class.perform_now(inbox)

    expect(backend.commands.size).to eq(described_class::BATCH)
    expect(Redis::Alfred.zcard(queue)).to eq(2)
    expect(described_class).to have_been_enqueued.with(inbox).exactly(:once)
  end

  it 'skips a file that fell out of a window narrowed after it was queued' do
    message = pending('OLD2', 20.days.ago)
    queue_up(message)
    channel.update!(provider_config: channel.provider_config.merge('history_media_days' => 7))

    described_class.perform_now(inbox)

    expect(backend.commands).to be_empty
    expect(message.reload.attachments).to be_empty
  end

  it 'does not ask again for a file the provider already gave up on' do
    message = pending('GONE1', 1.day.ago)
    message.update!(content_attributes: message.content_attributes.except('history_media'))
    queue_up(message)

    described_class.perform_now(inbox)

    expect(backend.commands).to be_empty
  end

  it 'stops asking once the inbox turns the automatic fetch off' do
    queue_up(pending('OFF1', 1.day.ago))
    channel.update!(provider_config: channel.provider_config.merge('history_media_fetch' => false))

    described_class.perform_now(inbox)

    expect(backend.commands).to be_empty
    expect(Redis::Alfred.exists?(described_class.scheduled_key(inbox))).to be(false)
  end

  [Whatsapp::Session::Errors::ProviderUnavailable, Whatsapp::Session::Errors::RateLimited].each do |error|
    it "keeps the file queued and comes back later on #{error.name.demodulize}" do
      message = pending('DOWN1', 1.day.ago)
      queue_up(message)
      allow(backend).to receive(:download_media).and_raise(error, 'try later')

      described_class.perform_now(inbox)

      expect(Redis::Alfred.zcard(queue)).to eq(1)
      expect(message.reload.content_attributes).to include('history_media' => true)
      expect(described_class).to have_been_enqueued.with(inbox)
    end
  end

  # Files written while the option was off were never queued, and importing again writes
  # nothing, so the run that follows the option growing has to find them itself.
  it 'collects the pending files the window covers before draining, when asked to' do
    inside = pending('IN1', 3.days.ago)
    pending('OUT1', 60.days.ago)
    described_class.kick(inbox, requeue: true)

    described_class.perform_now(inbox)

    expect(backend.commands.map(&:message_id)).to eq(['IN1'])
    expect(inside.reload.attachments.count).to eq(1)
  end

  # The window widened while a drain was already queued: the kick finds the run scheduled
  # and queues nothing, so the run that is there has to do the collecting.
  it 'keeps a rescan asked for while a drain is already scheduled' do
    queue_up(pending('Q1', 1.day.ago))
    described_class.kick(inbox)
    covered = pending('LATE1', 2.days.ago)
    described_class.kick(inbox, requeue: true)

    described_class.perform_now(inbox)

    expect(described_class).to have_been_enqueued.with(inbox).exactly(:once)
    expect(backend.commands.map(&:message_id)).to eq(%w[Q1 LATE1])
    expect(covered.reload.attachments.count).to eq(1)
  end

  it 'comes back for a rescan asked for while the last run was draining' do
    described_class.kick(inbox, requeue: true)
    allow(Whatsapp::Session::HistoryMedia).to receive(:requeue).and_wrap_original do |original, *args, **options|
      original.call(*args, **options).tap { described_class.kick(inbox, requeue: true) }
    end

    described_class.perform_now(inbox)

    expect(described_class).to have_been_enqueued.with(inbox).exactly(:twice)
  end

  it 'keeps the rescan asked for when the collection is cut short' do
    described_class.kick(inbox, requeue: true)
    allow(Whatsapp::Session::HistoryMedia).to receive(:requeue).and_raise(Interrupt)

    expect { described_class.perform_now(inbox) }.to raise_error(Interrupt)

    expect(Redis::Alfred.exists?(described_class.requeue_key(inbox))).to be(true)
  end

  # Imports of several inboxes at once: the history work of the whole instance shares the
  # import's slots, so the drains cannot take every Sidekiq thread.
  it 'waits for a history slot when the instance has none free' do
    queue_up(pending('SLOT1', 1.day.ago))
    allow(Whatsapp::Session::Inbound::ImportSlots).to receive(:concurrency).and_return(0)

    described_class.perform_now(inbox)

    expect(backend.commands).to be_empty
    expect(Redis::Alfred.zcard(queue)).to eq(1)
    expect(described_class).to have_been_enqueued.with(inbox)
  end

  it 'gives the history slot back when the run ends' do
    queue_up(pending('SLOT2', 1.day.ago))

    described_class.perform_now(inbox)

    expect(Whatsapp::Session::Inbound::ImportSlots.taken).to eq(0)
  end

  it 'hands the queue back once a batch has run for its time, whatever its size' do
    queue_up(pending('SLOW1', 1.hour.ago), pending('SLOW2', 2.hours.ago))
    allow(backend).to receive(:download_media).and_wrap_original do |original, command|
      travel(described_class::BATCH_TIME + 1.second)
      original.call(command)
    end

    described_class.perform_now(inbox)

    expect(backend.commands.map(&:message_id)).to eq(['SLOW1'])
    expect(described_class).to have_been_enqueued.with(inbox)
  end

  it 'keeps a rescan request however long the queue takes to reach it' do
    described_class.kick(inbox, requeue: true)

    expect(Redis::Alfred.ttl(described_class.requeue_key(inbox))).to eq(-1)
  end

  it 'leaves the claim free when the drain could not be queued' do
    allow(described_class).to receive(:set).and_raise(Redis::CannotConnectError)

    expect { described_class.kick(inbox) }.to raise_error(Redis::CannotConnectError)

    expect(Redis::Alfred.exists?(described_class.scheduled_key(inbox))).to be(false)
  end

  # The scheduling claim lapsed while the run sat in the queue, and a second run was queued
  # behind it: only one may download.
  it 'leaves a second run of the same inbox while one is working' do
    queue_up(pending('TWICE1', 1.day.ago))
    Redis::Alfred.set(described_class.run_key(inbox), 'other run')

    described_class.perform_now(inbox)

    expect(backend.commands).to be_empty
    expect(Redis::Alfred.get(described_class.run_key(inbox))).to eq('other run')
  end

  # The next run can start the moment it is queued; finding this run's claim still there,
  # it would leave, and the drain would stop.
  it 'gives its run claim back before queuing the next run' do
    queue_up(*Array.new(described_class::BATCH + 1) { |index| pending("C#{index}", index.hours.ago) })
    claims = []
    allow(described_class).to receive(:set).and_wrap_original do |original, *args|
      claims << Redis::Alfred.exists?(described_class.run_key(inbox))
      original.call(*args)
    end

    described_class.perform_now(inbox)

    expect(claims).to eq([false])
  end

  it 'picks a collection that ran out of time up where it stopped, on the next run' do
    described_class.kick(inbox, requeue: true)
    allow(Whatsapp::Session::HistoryMedia).to receive(:requeue).and_return(42, nil)

    described_class.perform_now(inbox)
    expect(Redis::Alfred.exists?(described_class.requeue_key(inbox))).to be(true)
    described_class.perform_now(inbox)

    expect(Whatsapp::Session::HistoryMedia).to have_received(:requeue).with(inbox, from: nil, deadline: anything).ordered
    expect(Whatsapp::Session::HistoryMedia).to have_received(:requeue).with(inbox, from: 42, deadline: anything).ordered
    expect(Redis::Alfred.exists?(described_class.requeue_key(inbox))).to be(false)
  end

  # The window widened again while a walk was half done: the new request's messages can
  # sit above the old cursor.
  it 'starts over for a new rescan request instead of resuming the old one' do
    described_class.kick(inbox, requeue: true)
    allow(Whatsapp::Session::HistoryMedia).to receive(:requeue).and_return(42, nil)
    described_class.perform_now(inbox)
    described_class.kick(inbox, requeue: true)

    described_class.perform_now(inbox)

    expect(Whatsapp::Session::HistoryMedia).to have_received(:requeue).with(inbox, from: nil, deadline: anything).twice
  end

  it 'leaves the claim free when its own continuation could not be queued' do
    queue_up(*Array.new(described_class::BATCH + 1) { |index| pending("E#{index}", index.hours.ago) })
    described_class.kick(inbox)
    allow(described_class).to receive(:set).and_raise(Redis::CannotConnectError)

    expect { described_class.perform_now(inbox) }.to raise_error(Redis::CannotConnectError)

    expect(Redis::Alfred.exists?(described_class.scheduled_key(inbox))).to be(false)
  end

  # A file tracked the moment scheduling reopens starts a run at once; this run must not
  # still be holding the run claim then.
  it 'gives its run claim back before it reopens scheduling' do
    described_class.kick(inbox)
    held = nil
    allow(Redis::Alfred).to receive(:delete).and_wrap_original do |original, key|
      held = Redis::Alfred.exists?(described_class.run_key(inbox)) if key == described_class.scheduled_key(inbox)
      original.call(key)
    end

    described_class.perform_now(inbox)

    expect(held).to be(false)
  end

  # A deploy or a crash stops the worker in the middle of a download. The job goes back
  # to Sidekiq, and the file has to be there when it runs again.
  it 'keeps the file it was working on when the worker stops mid-download' do
    message = pending('MID1', 1.day.ago)
    queue_up(message)
    allow(backend).to receive(:download_media).and_raise(Interrupt)

    expect { described_class.perform_now(inbox) }.to raise_error(Interrupt)

    expect(Redis::Alfred.zcard(queue)).to eq(1)
  end

  it 'reports a file whose stored description cannot be read and goes on with the rest' do
    broken = pending('BAD1', 1.hour.ago)
    fine = pending('OK1', 2.hours.ago)
    queue_up(broken, fine)
    allow(backend).to receive(:download_media).and_wrap_original do |original, command|
      raise Whatsapp::Session::Errors::InvalidPayload, 'unreadable' if command.message_id == 'BAD1'

      original.call(command)
    end
    tracker = instance_double(ChatwootExceptionTracker, capture_exception: true)
    allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker)

    described_class.perform_now(inbox)

    expect(tracker).to have_received(:capture_exception)
    expect(fine.reload.attachments.count).to eq(1)
    expect(broken.reload.content_attributes).to include('history_media' => true)
    expect(Redis::Alfred.zcard(queue)).to eq(0)
  end

  # Storage down or the inbox misconfigured: every file would fail the same way, and
  # treating each as its own problem would empty the whole queue.
  it 'fails the run and keeps the queue on a failure that is not the file' do
    queue_up(pending('CFG1', 1.hour.ago), pending('CFG2', 2.hours.ago))
    allow(backend).to receive(:download_media).and_raise(Whatsapp::Session::Errors::InvalidConfig, 'no session id')

    expect { described_class.perform_now(inbox) }.to raise_error(Whatsapp::Session::Errors::InvalidConfig)

    expect(Redis::Alfred.zcard(queue)).to eq(2)
  end

  # The operator changes the setting while a batch is running; the job loaded the channel
  # before the change.
  it 'stops at the next file when the option is turned off in the middle of a batch' do
    queue_up(pending('A1', 1.hour.ago), pending('A2', 2.hours.ago))
    allow(backend).to receive(:download_media).and_wrap_original do |original, command|
      Channel::Whatsapp.find(channel.id).update!(provider_config: channel.provider_config.merge('history_media_fetch' => false))
      original.call(command)
    end

    described_class.perform_now(inbox)

    expect(backend.commands.map(&:message_id)).to eq(['A1'])
  end

  it 'skips the rest of a batch that a window narrowed in the middle of it left out' do
    queue_up(pending('B1', 1.hour.ago), pending('B2', 20.days.ago))
    allow(backend).to receive(:download_media).and_wrap_original do |original, command|
      Channel::Whatsapp.find(channel.id).update!(provider_config: channel.provider_config.merge('history_media_days' => 7))
      original.call(command)
    end

    described_class.perform_now(inbox)

    expect(backend.commands.map(&:message_id)).to eq(['B1'])
  end

  # One drain per inbox is what keeps its history to one download at a time.
  it 'queues a single run however many files are tracked while one is pending' do
    3.times { |index| Whatsapp::Session::HistoryMedia.track(pending("T#{index}", index.hours.ago)) }

    expect(described_class).to have_been_enqueued.with(inbox).exactly(:once)
  end

  it 'lets the next file start a run once the queue has drained' do
    Whatsapp::Session::HistoryMedia.track(pending('LAST1', 1.day.ago))
    described_class.perform_now(inbox)

    Whatsapp::Session::HistoryMedia.track(pending('NEXT1', 2.days.ago))

    expect(described_class).to have_been_enqueued.with(inbox).exactly(:twice)
  end
end
