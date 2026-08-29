require 'rails_helper'

RSpec.describe Redis::LockManager do
  let(:lock_manager) { described_class.new }
  let(:lock_key) { 'test_lock' }

  after do
    # Cleanup: Ensure that the lock key is deleted after each test to avoid interference
    Redis::Alfred.delete(lock_key)
  end

  describe '#lock' do
    it 'acquires a lock and returns true' do
      expect(lock_manager.lock(lock_key)).to be true
      expect(lock_manager.locked?(lock_key)).to be true
    end

    it 'returns false if the lock is already acquired' do
      lock_manager.lock(lock_key)
      expect(lock_manager.lock(lock_key)).to be false
    end

    it 'can acquire a lock again after the timeout' do
      lock_manager.lock(lock_key, 1) # 1-second timeout
      sleep 2
      expect(lock_manager.lock(lock_key)).to be true
    end
  end

  describe '#unlock' do
    it 'releases a lock' do
      lock_manager.lock(lock_key)
      lock_manager.unlock(lock_key)
      expect(lock_manager.locked?(lock_key)).to be false
    end
  end

  describe '#with_lock' do
    it 'yields when the lock is acquired and releases the lock' do
      yielded = false

      expect(lock_manager.with_lock(lock_key) { yielded = true }).to be true
      expect(yielded).to be true
      expect(lock_manager.locked?(lock_key)).to be false
    end

    it 'returns false without yielding when the lock is already acquired' do
      lock_manager.lock(lock_key)

      expect { |block| lock_manager.with_lock(lock_key, &block) }.not_to yield_control
      expect(lock_manager.with_lock(lock_key) { raise 'should not run' }).to be false
    end

    it 'releases the lock when the block raises' do
      expect { lock_manager.with_lock(lock_key) { raise 'boom' } }.to raise_error('boom')
      expect(lock_manager.locked?(lock_key)).to be false
    end
  end

  describe '#locked?' do
    it 'returns true if a key is locked' do
      lock_manager.lock(lock_key)
      expect(lock_manager.locked?(lock_key)).to be true
    end

    it 'returns false if a key is not locked' do
      expect(lock_manager.locked?(lock_key)).to be false
    end
  end
end
