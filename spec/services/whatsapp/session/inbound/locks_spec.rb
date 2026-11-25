require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Locks do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:chat) { '5541999990000' }
  let(:message_id) { '3EB0AAAA0001' }

  describe '.with_chat_lock' do
    it 'runs the block and releases the chat' do
      expect(described_class.with_chat_lock(inbox, chat) { :done }).to eq(:done)
      expect(Redis::Alfred.get(described_class.chat_key(inbox, chat))).to be_nil
    end

    it 'refuses a chat another worker holds' do
      described_class.with_chat_lock(inbox, chat) do
        expect { described_class.with_chat_lock(inbox, chat) { :nested } }.to raise_error(described_class::Busy)
      end
    end

    # WhatsApp names the same 1:1 peer by phone in one event and by LID in the next, and
    # both resolve to one contact: locking only the id an event carries let a worker
    # holding the other alias run alongside, and each opened a conversation of its own.
    it 'refuses a chat another worker holds under a different alias' do
      described_class.with_chat_lock(inbox, %w[5541999990000 182736451928374]) do
        expect { described_class.with_chat_lock(inbox, '182736451928374') { :nested } }
          .to raise_error(described_class::Busy)
      end
    end

    it 'releases every alias it took' do
      described_class.with_chat_lock(inbox, %w[5541999990000 182736451928374]) { :done }

      expect(Redis::Alfred.get(described_class.chat_key(inbox, '182736451928374'))).to be_nil
      expect(Redis::Alfred.get(described_class.chat_key(inbox, '5541999990000'))).to be_nil
    end

    # The second alias being held is a Busy for the whole call, and the first must not be
    # left behind: the next delivery would find it locked by nobody until the TTL.
    it 'releases what it took when a later alias is already held' do
      Redis::Alfred.set(described_class.chat_key(inbox, '182736451928374'), 'other', ex: 30)

      expect { described_class.with_chat_lock(inbox, %w[5541999990000 182736451928374]) { :never } }
        .to raise_error(described_class::Busy)

      expect(Redis::Alfred.get(described_class.chat_key(inbox, '5541999990000'))).to be_nil
    end

    # An operation that outran the TTL, syncing a large group roster being the realistic
    # one, used to delete the lock a second worker had already taken: from there the two
    # interleave their conversation, membership and activity writes.
    it 'leaves a lock another worker took over in place' do
      key = described_class.chat_key(inbox, chat)

      described_class.with_chat_lock(inbox, chat) do
        Redis::Alfred.delete(key)
        Redis::Alfred.set(key, 'another-worker', ex: 30)
      end

      expect(Redis::Alfred.get(key)).to eq('another-worker')
    end
  end

  # Two numbers, not one. The live inbound path is the only caller that stands and waits,
  # and it waits for the seconds an album takes to finish arriving -- which says nothing
  # about how long the work behind the key runs once it has it.
  describe 'waiting for a chat' do
    it 'answers Busy without waiting when it was given no wait' do
      Redis::Alfred.set(described_class.chat_key(inbox, chat), 'other', ex: 30)

      elapsed = Benchmark.realtime do
        expect { described_class.with_chat_lock(inbox, chat) { :never } }.to raise_error(described_class::Busy)
      end

      expect(elapsed).to be < 0.1
    end

    it 'takes the chat when the holder releases it inside the wait' do
      key = described_class.chat_key(inbox, chat)
      Redis::Alfred.set(key, 'other', ex: 30)
      Thread.new do
        sleep(0.2)
        Redis::Alfred.delete(key)
      end

      expect(described_class.with_chat_lock(inbox, chat, wait: 2.seconds) { :taken }).to eq(:taken)
    end

    it 'gives up once the wait is spent' do
      Redis::Alfred.set(described_class.chat_key(inbox, chat), 'other', ex: 30)

      expect { described_class.with_chat_lock(inbox, chat, wait: 0.2.seconds) { :never } }
        .to raise_error(described_class::Busy)
    end

    # The whole point of separating them: a caller that waited a moment still holds the key
    # for as long as its own work needs, and a lock that expires under the block it guards
    # is not a lock.
    it 'holds the chat for its ttl and not for what it waited' do
      described_class.with_chat_lock(inbox, chat, wait: 0.2.seconds, ttl: 45.seconds) do
        expect(Redis::Alfred.ttl(described_class.chat_key(inbox, chat))).to be > 40
      end
    end
  end

  describe '.with_message_lock' do
    it 'releases the marker so a later pass can run' do
      described_class.with_message_lock(inbox, message_id) { :first }

      expect(described_class.with_message_lock(inbox, message_id) { :second }).to eq(:second)
    end

    # Answering ":duplicate" here acknowledges the event: a worker killed between taking
    # the marker and writing the row would turn its own retry into a lost message. What
    # makes a finished message a duplicate is its stored source_id, which the caller
    # checks inside the block.
    it 'asks for a retry while the marker is held instead of calling it a duplicate' do
      Redis::Alfred.set(described_class.message_key(inbox, message_id), true, ex: 30)

      expect { described_class.with_message_lock(inbox, message_id) { :ran } }.to raise_error(described_class::Busy)
    end

    # Same failure the chat lock had: a pass that outran the TTL deleted the marker a
    # redelivery had already taken, and a third delivery could then run alongside it.
    it 'leaves a marker another worker took over in place' do
      key = described_class.message_key(inbox, message_id)

      described_class.with_message_lock(inbox, message_id) do
        Redis::Alfred.delete(key)
        Redis::Alfred.set(key, 'another-worker', ex: 30)
      end

      expect(Redis::Alfred.get(key)).to eq('another-worker')
    end

    it 'runs unguarded when there is no id to key on' do
      expect(described_class.with_message_lock(inbox, nil) { :ran }).to eq(:ran)
    end
  end

  # An import holds a chat for a whole batch, and one dump is a dozen batches: they hand
  # the key to each other, so a live message beside them can lose every attempt it has
  # against a lock that is never free at the moment it looks. Retrying harder does not fix
  # that -- a budget covers one holder, and this is a queue of them.
  describe 'giving way to a caller that is waiting' do
    it 'stands aside for a chat somebody said they wanted' do
      described_class.note_waiter(inbox, chat)

      expect { described_class.with_chat_lock(inbox, chat, defer_to_waiters: true) { :imported } }
        .to raise_error(described_class::Busy)
    end

    it 'takes a free chat nobody is waiting for' do
      expect(described_class.with_chat_lock(inbox, chat, defer_to_waiters: true) { :imported }).to eq(:imported)
    end

    # Otherwise the batches of one dump stand aside for each other and the import never
    # runs, which is a deadlock wearing the fix's clothes.
    it 'does not register itself as waiting when it is refused' do
      described_class.with_chat_lock(inbox, chat) do
        expect { described_class.with_chat_lock(inbox, chat, defer_to_waiters: true) { :imported } }
          .to raise_error(described_class::Busy)
      end

      expect(described_class.waiting?(inbox, chat)).to be(false)
    end

    it 'says it is waiting when it is refused a chat' do
      described_class.with_chat_lock(inbox, chat) do
        expect { described_class.with_chat_lock(inbox, chat) { :live } }.to raise_error(described_class::Busy)
      end

      expect(described_class.waiting?(inbox, chat)).to be(true)
    end

    # Nothing clears the note, and that is the point: it is shared by everybody waiting on
    # the chat, so the first caller to be served would be deleting a claim the others still
    # hold and an import could cut in ahead of them. It ends by expiring.
    it 'keeps standing aside while a second caller is still waiting' do
      described_class.with_chat_lock(inbox, chat) do
        expect { described_class.with_chat_lock(inbox, chat) { :live_one } }.to raise_error(described_class::Busy)
        expect { described_class.with_chat_lock(inbox, chat) { :live_two } }.to raise_error(described_class::Busy)
      end

      described_class.with_chat_lock(inbox, chat) { :live_one_served }

      expect(described_class.waiting?(inbox, chat)).to be(true)
    end

    # And it is a claim on the next turn rather than a standing one, so an import is held
    # off for one window and not forever.
    it 'stops standing aside once the note has expired' do
      described_class.note_waiter(inbox, chat)

      travel(described_class::WAITER_TTL + 1.second) do
        expect(described_class.with_chat_lock(inbox, chat, defer_to_waiters: true) { :imported }).to eq(:imported)
      end
    end
  end
end
