require 'rails_helper'

RSpec.describe BaileysHelper do
  describe '#baileys_extract_message_timestamp' do
    let(:timestamp_low) { 1_748_003_165 }
    let(:timestamp_hash) { { 'low' => timestamp_low, 'high' => 1, 'unsigned' => true } }

    it 'extracts the timestamp from a string' do
      expect(baileys_extract_message_timestamp(timestamp_low.to_s)).to eq(timestamp_low)
    end

    it 'extracts the timestamp from an int' do
      expect(baileys_extract_message_timestamp(timestamp_low)).to eq(timestamp_low)
    end

    it 'extracts the timestamp from a hash' do
      expect(baileys_extract_message_timestamp(timestamp_hash)).to eq(6_042_970_461)
    end
  end

  describe '#with_baileys_channel_lock_on_outgoing_message' do
    let(:channel_id) { 1 }
    let(:lock_key) { format(BaileysHelper::CHANNEL_LOCK_ON_OUTGOING_MESSAGE_KEY, channel_id: channel_id) }
    let(:timeout) { BaileysHelper::CHANNEL_LOCK_ON_OUTGOING_MESSAGE_TIMEOUT }

    before do
      allow(Redis::Alfred).to receive(:set).and_return(true)
      allow(Redis::Alfred).to receive(:delete)
    end

    context 'when a block is given' do
      it 'yields to the block' do
        expect { |b| with_baileys_channel_lock_on_outgoing_message(channel_id, &b) }.to yield_control
      end

      it 'attempts to acquire the lock' do
        with_baileys_channel_lock_on_outgoing_message(channel_id) { nil }

        expect(Redis::Alfred).to have_received(:set).with(lock_key, 1, nx: true, ex: timeout)
      end

      it 'clears the lock after the block executes' do
        with_baileys_channel_lock_on_outgoing_message(channel_id) { nil }

        expect(Redis::Alfred).to have_received(:delete).with(lock_key)
      end

      it 'clears the lock even if the block raises an error' do
        expect do
          with_baileys_channel_lock_on_outgoing_message(channel_id) { raise 'test error' }
        end.to raise_error('test error')

        expect(Redis::Alfred).to have_received(:delete).with(lock_key)
      end

      context 'when lock is acquired immediately' do
        it 'executes the block and clears the lock' do
          expect { |b| with_baileys_channel_lock_on_outgoing_message(channel_id, &b) }.to yield_control
          expect(Redis::Alfred).to have_received(:set).with(lock_key, 1, nx: true, ex: timeout)
          expect(Redis::Alfred).to have_received(:delete).with(lock_key)
        end
      end

      context 'when lock is not acquired immediately but within timeout' do
        it 'retries acquiring the lock, executes the block, and clears the lock' do
          allow(Redis::Alfred).to receive(:set).and_return(false, true)
          allow(self).to receive(:sleep)

          expect { |b| with_baileys_channel_lock_on_outgoing_message(channel_id, &b) }.to yield_control
          expect(Redis::Alfred).to have_received(:set).with(lock_key, 1, nx: true, ex: timeout).twice
          expect(self).to have_received(:sleep).with(0.1).once
          expect(Redis::Alfred).to have_received(:delete).once.with(lock_key)
        end
      end

      context 'when lock is not acquired within timeout' do
        it 'still executes the block and clears the lock' do
          freeze_time
          allow(Redis::Alfred).to receive(:set).and_return(false)
          allow(self).to receive(:sleep) { travel_to 1.second.from_now }

          expect { |b| with_baileys_channel_lock_on_outgoing_message(channel_id, &b) }.to yield_control
          expect(Redis::Alfred).to have_received(:set)
            .with(lock_key, 1, nx: true, ex: timeout)
            .exactly(BaileysHelper::CHANNEL_LOCK_ON_OUTGOING_MESSAGE_TIMEOUT.to_i)
          expect(Redis::Alfred).to have_received(:delete).once.with(lock_key)
        end
      end
    end

    context 'when no block is given' do
      it 'raises an ArgumentError' do
        expect do
          with_baileys_channel_lock_on_outgoing_message(channel_id)
        end.to raise_error(ArgumentError,
                           'A block is required for with_baileys_channel_lock_on_outgoing_message')
      end
    end
  end
end
