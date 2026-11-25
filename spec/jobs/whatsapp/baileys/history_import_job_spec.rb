require 'rails_helper'

RSpec.describe Whatsapp::Baileys::HistoryImportJob do
  let(:slots) { Whatsapp::Session::Inbound::ImportSlots }
  let(:channel) do
    create(:channel_whatsapp, provider: 'baileys', provider_config: { webhook_verify_token: 'valid_token' },
                              validate_provider_config: false, received_messages: false)
  end
  let(:inbox) { channel.inbox }
  let(:batch) { [{ key: { id: 'A1', remoteJid: '5511912345678@s.whatsapp.net', fromMe: false } }] }

  # A slot is instance-wide state and MockRedis is not flushed between examples.
  after { Redis::Alfred.delete(slots::KEY) }

  def job(watermark = nil) = described_class.new(inbox, batch, watermark, false)

  def importing(&)
    allow(Whatsapp::Baileys::HistoryImporter).to receive(:new) do
      instance_double(Whatsapp::Baileys::HistoryImporter).tap { |importer| allow(importer).to receive(:perform, &) }
    end
  end

  describe 'the instance-wide cap' do
    around { |example| with_modified_env(HISTORY_IMPORT_MAX_CONCURRENCY: '2') { example.run } }

    # Each import starts the next one from inside itself, so the three overlap the way
    # three Sidekiq threads would. The third finds both slots taken.
    it 'never runs more imports at once than the cap, and files the one it turned away for later' do
      running = 0
      peak = 0
      importing do
        running += 1
        peak = [peak, running].max
        described_class.perform_now(inbox, batch, running, false)
        running -= 1
      end

      expect { job.perform_now }.to have_enqueued_job(described_class).with(inbox, batch, 2, false)
                                                                      .on_queue(slots::WAITING_QUEUE)
      expect(peak).to eq(2)
    end

    it 'gives the slot back when the import is done' do
      importing { nil }

      3.times { job.perform_now }

      expect(Whatsapp::Baileys::HistoryImporter).to have_received(:new).exactly(3).times
      expect(slots.taken).to eq(0)
    end

    # The chat lock answers Busy while the same chat's siblings run. A batch that kept
    # its slot while it waited would hold the cap for nothing and starve every other chat.
    it 'gives the slot back when the chat is busy, and retries on the chat budget' do
      importing { raise Whatsapp::Session::Inbound::Locks::Busy, 'chat locked' }

      expect { job.perform_now }.to have_enqueued_job(described_class)
      expect(slots.taken).to eq(0)
    end

    it 'gives the slot back when the import fails' do
      importing { raise ArgumentError, 'broken batch' }

      expect { job.perform_now }.to raise_error(ArgumentError)
      expect(slots.taken).to eq(0)
    end

    # Waiting for a slot is not a failure: a dump of thousands of batches keeps most of
    # them waiting, and the budget belongs to the chat lock it was sized for.
    it 'does not spend the retry budget of the chat lock while waiting for a slot' do
      2.times { slots.claim(2) }
      importing { nil }

      job.perform_now
      enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.last

      expect(Whatsapp::Baileys::HistoryImporter).not_to have_received(:new)
      expect(enqueued['exception_executions']).to eq({})
      expect(enqueued['queue_name']).to eq(slots::WAITING_QUEUE)
    end

    # A batch sleeping out a fixed delay is nowhere near the slot when it frees up, and at a
    # cap of 1 that left the slot idle for most of every window. The waiting queue has no
    # timer: whoever gives a slot back wakes the batch that has waited longest.
    it 'files a batch that found no slot in the waiting queue, with no delay' do
      2.times { slots.claim(2) }
      importing { nil }

      job.perform_now
      enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.last

      expect(enqueued['queue_name']).to eq(slots::WAITING_QUEUE)
      expect(enqueued['scheduled_at']).to be_nil
    end

    it 'wakes the waiting batches when it gives its slot back' do
      allow(slots).to receive(:top_up)
      importing { nil }

      job.perform_now

      expect(slots).to have_received(:top_up).with(into: described_class.queue_name)
    end

    it 'wakes the waiting batches when it gives back the slot of an import that failed' do
      allow(slots).to receive(:top_up)
      importing { raise ArgumentError, 'broken batch' }

      expect { job.perform_now }.to raise_error(ArgumentError)
      expect(slots).to have_received(:top_up).with(into: described_class.queue_name)
    end

    # A slot can be given back between the claim that found none and the line that files
    # the batch, and then the batch waits with nobody left to wake it.
    it 'wakes the waiting batches after filing one, in case a slot freed up meanwhile' do
      2.times { slots.claim(2) }
      allow(slots).to receive(:top_up)
      importing { nil }

      job.perform_now

      expect(slots).to have_received(:top_up).with(into: described_class.queue_name)
    end

    # A woken batch that never takes a slot gives none back, so without this the next one
    # waits for the sweep.
    it 'wakes the next batch when it is dropped for an inbox that is gone' do
      allow(slots).to receive(:top_up)

      described_class.perform_now(nil, batch, nil, false)

      expect(slots).to have_received(:top_up).with(into: described_class.queue_name)
    end

    # An inbox deleted while its batches waited fails them before `perform`: the arguments
    # no longer deserialize and the batch is dropped there, holding no slot and waking nobody.
    it 'wakes the next batch when it is dropped for an inbox that no longer deserializes' do
      serialized = job.serialize
      serialized['arguments'][0] = { '_aj_globalid' => "gid://#{GlobalID.app}/Inbox/0" }
      allow(slots).to receive(:top_up)

      ActiveJob::Base.execute(serialized)

      expect(slots).to have_received(:top_up).with(into: described_class.queue_name)
    end

    # The waiting queue is where a batch sits, not where it runs: a woken batch that finds
    # its chat busy goes back to the chat lock's retries on its own queue.
    it 'retries a woken batch on its own queue when the chat is busy' do
      importing { raise Whatsapp::Session::Inbound::Locks::Busy, 'chat locked' }
      woken = job.tap { |j| j.queue_name = slots::WAITING_QUEUE }

      expect { woken.perform_now }.to have_enqueued_job(described_class).on_queue(described_class.queue_name)
    end

    # A worker killed mid-import never runs its `ensure`. The slot it held has to come
    # back on its own, or two kills put an end to history import on the whole instance.
    #
    # The second lease is taken halfway through the first, as a busy instance would, so the
    # set itself is still alive when the first one runs out.
    it 'takes back a slot whose holder never returned it once the lease runs out' do
      half = slots::LEASE / 2
      slots.claim(2)
      travel(half) { slots.claim(2) }
      importing { nil }

      travel(half) { job.perform_now }
      expect(Whatsapp::Baileys::HistoryImporter).not_to have_received(:new)

      travel(slots::LEASE + 1.second) { job.perform_now }
      expect(Whatsapp::Baileys::HistoryImporter).to have_received(:new).once
    end
  end

  describe 'the cap setting' do
    it 'defaults to a handful' do
      expect(slots.concurrency).to eq(slots::DEFAULT_CONCURRENCY)
      expect(slots::DEFAULT_CONCURRENCY).to be_between(1, 8)
    end

    it 'reads the setting' do
      with_modified_env(HISTORY_IMPORT_MAX_CONCURRENCY: '7') { expect(slots.concurrency).to eq(7) }
    end

    # Zero would park every batch forever and a garbled value would do the same through
    # `to_i`, both in silence. The default is the answer that keeps the import moving.
    %w[abc -1 0 2.5].each do |value|
      it "falls back to the default for #{value.inspect}" do
        with_modified_env(HISTORY_IMPORT_MAX_CONCURRENCY: value) do
          expect(slots.concurrency).to eq(slots::DEFAULT_CONCURRENCY)
        end
      end
    end
  end
end
