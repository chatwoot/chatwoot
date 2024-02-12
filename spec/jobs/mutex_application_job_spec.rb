require 'rails_helper'

RSpec.describe MutexApplicationJob do
  let(:lock_manager) { instance_double(Redis::LockManager) }
  let(:lock_key) { 'test_key' }

  let(:test_mutex_job_class) do
    stub_const('TestMutexJob', Class.new(MutexApplicationJob) do
      def perform
        with_lock('test_key') do
          # Do nothing
        end
      end
    end)
  end

  before do
    allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
    allow(lock_manager).to receive(:lock).and_return(true)
    allow(lock_manager).to receive(:unlock).and_return(true)
  end

  describe '#with_lock' do
    it 'acquires the lock and yields the block if lock is not acquired' do
      expect(lock_manager).to receive(:lock).with(lock_key).and_return(true)
      expect(lock_manager).to receive(:unlock).with(lock_key).and_return(true)

      expect { |b| described_class.new.send(:with_lock, lock_key, &b) }.to yield_control
    end

    it 'raises LockAcquisitionError if it cannot acquire the lock' do
      allow(lock_manager).to receive(:lock).with(lock_key).and_return(false)

      expect do
        described_class.new.send(:with_lock, lock_key) do
          # Do nothing
        end
      end.to raise_error(MutexApplicationJob::LockAcquisitionError)
    end

    it 'ensures that the lock is released even if there is an error during block execution' do
      expect(lock_manager).to receive(:lock).with(lock_key).and_return(true)
      expect(lock_manager).to receive(:unlock).with(lock_key).and_return(true)

      expect do
        described_class.new.send(:with_lock, lock_key) { raise StandardError }
      end.to raise_error(StandardError)
    end
  end
end
