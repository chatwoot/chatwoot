require 'rails_helper'

RSpec.describe MutexApplicationJob do
  let(:lock_manager) { instance_double(Redis::LockManager) }
  let(:lock_key) { 'test_key' }

  before do
    allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
    allow(lock_manager).to receive(:lock).and_return(true)
    allow(lock_manager).to receive(:unlock).and_return(true)
  end

  describe '#with_lock' do
    it 'acquires the lock and yields the block if lock is not acquired' do
      expect(lock_manager).to receive(:lock).with(lock_key, Redis::LockManager::LOCK_TIMEOUT).and_return(true)
      expect(lock_manager).to receive(:unlock).with(lock_key).and_return(true)

      expect { |b| described_class.new.send(:with_lock, lock_key, &b) }.to yield_control
    end

    it 'acquires the lock with custom timeout' do
      expect(lock_manager).to receive(:lock).with(lock_key, 5.seconds).and_return(true)
      expect(lock_manager).to receive(:unlock).with(lock_key).and_return(true)

      expect { |b| described_class.new.send(:with_lock, lock_key, 5.seconds, &b) }.to yield_control
    end

    it 'raises LockAcquisitionError if it cannot acquire the lock' do
      allow(lock_manager).to receive(:lock).with(lock_key, Redis::LockManager::LOCK_TIMEOUT).and_return(false)

      expect do
        described_class.new.send(:with_lock, lock_key) do
          # Do nothing
        end
      end.to raise_error(StandardError) { |error| expect(error.class.name).to eq('MutexApplicationJob::LockAcquisitionError') }
    end

    it 'raises StandardError if it execution raises it' do
      allow(lock_manager).to receive(:lock).with(lock_key, Redis::LockManager::LOCK_TIMEOUT).and_return(false)
      allow(lock_manager).to receive(:unlock).with(lock_key).and_return(true)

      expect do
        described_class.new.send(:with_lock, lock_key) do
          raise StandardError
        end
      end.to raise_error(StandardError)
    end

    it 'ensures that the lock is released even if there is an error during block execution' do
      expect(lock_manager).to receive(:lock).with(lock_key, Redis::LockManager::LOCK_TIMEOUT).and_return(true)
      expect(lock_manager).to receive(:unlock).with(lock_key).and_return(true)

      expect do
        described_class.new.send(:with_lock, lock_key) { raise StandardError }
      end.to raise_error(StandardError)
    end
  end

  describe '.retry_on_lock_conflict' do
    let(:job_class) do
      Class.new(MutexApplicationJob) do
        retry_on_lock_conflict wait: 1.second, attempts: 1, on_exhaustion: :process_without_lock

        attr_reader :fallback_args

        def perform(lock_key, _payload)
          with_lock(lock_key) { raise 'lock should not be acquired' }
        end

        def process_without_lock(lock_key, payload)
          @fallback_args = [lock_key, payload]
        end
      end
    end

    let(:payload) { { 'message' => 'hello' } }

    before do
      stub_const('LockConflictTestJob', job_class)
    end

    it 'runs the configured handler with the original job arguments when lock retries are exhausted' do
      allow(lock_manager).to receive(:lock).with(lock_key, Redis::LockManager::LOCK_TIMEOUT).and_return(false)

      job = job_class.new(lock_key, payload)

      expect { job.perform_now }.not_to raise_error
      expect(job.fallback_args).to eq([lock_key, payload])
    end

    context 'without an exhaustion handler' do
      let(:job_class) do
        Class.new(MutexApplicationJob) do
          retry_on_lock_conflict wait: 1.second, attempts: 1

          def perform(lock_key)
            with_lock(lock_key) { raise 'lock should not be acquired' }
          end
        end
      end

      it 'raises the lock acquisition error when retries are exhausted' do
        allow(lock_manager).to receive(:lock).with(lock_key, Redis::LockManager::LOCK_TIMEOUT).and_return(false)

        expect do
          job_class.perform_now(lock_key)
        end.to raise_error(StandardError) { |error| expect(error.class.name).to eq('MutexApplicationJob::LockAcquisitionError') }
      end
    end
  end
end
