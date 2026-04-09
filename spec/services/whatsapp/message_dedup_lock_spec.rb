require 'rails_helper'

describe Whatsapp::MessageDedupLock do
  let(:source_id) { "wamid.test_#{SecureRandom.hex(8)}" }
  let(:lock) { described_class.new(source_id) }
  let(:redis_key) { format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: source_id) }

  after { Redis::Alfred.delete(redis_key) }

  describe '#acquire!' do
    it 'returns truthy on first acquire' do
      expect(lock.acquire!).to be_truthy
    end

    it 'returns falsy on second acquire for the same source_id' do
      lock.acquire!
      expect(described_class.new(source_id).acquire!).to be_falsy
    end

    it 'allows different source_ids to acquire independently' do
      lock.acquire!
      other = described_class.new("wamid.other_#{SecureRandom.hex(8)}")
      expect(other.acquire!).to be_truthy
    end

    it 'lets exactly one thread win when two race for the same source_id' do
      results = Concurrent::Array.new
      barrier = Concurrent::CyclicBarrier.new(2)

      threads = Array.new(2) do
        Thread.new do
          barrier.wait
          results << described_class.new(source_id).acquire!
        end
      end

      threads.each(&:join)

      wins = results.count { |r| r }
      expect(wins).to eq(1), "Expected exactly 1 winner but got #{wins}. Results: #{results.inspect}"
    end
  end
end
