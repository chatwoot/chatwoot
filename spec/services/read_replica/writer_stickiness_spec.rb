require 'rails_helper'

RSpec.describe ReadReplica::WriterStickiness do
  let(:actor_key) { 'account:1:user:2' }
  let(:redis_key) { 'read-replica:writer-sticky:account:1:user:2' }

  before do
    allow(ReadReplica::Configuration).to receive(:enabled?).and_return(true)
    allow(ReadReplica::Configuration).to receive(:writer_stickiness_ttl).and_return(60.seconds)
  end

  describe '.sticky?' do
    it 'checks the actor-specific Redis key' do
      allow(Redis::Alfred).to receive(:exists?).with(redis_key).and_return(true)

      expect(described_class.sticky?(actor_key)).to be(true)
    end

    it 'fails closed when Redis is unavailable' do
      allow(Redis::Alfred).to receive(:exists?).and_raise(Redis::BaseError, 'unavailable')

      expect(described_class.sticky?(actor_key)).to be(true)
    end

    it 'does not query Redis without an actor' do
      expect(Redis::Alfred).not_to receive(:exists?)

      expect(described_class.sticky?(nil)).to be(false)
    end
  end

  describe '.mark!' do
    it 'does not write while replica routing is disabled' do
      allow(ReadReplica::Configuration).to receive(:enabled?).and_return(false)
      expect(Redis::Alfred).not_to receive(:set)

      described_class.mark!(actor_key)
    end

    it 'sets the actor key with the configured expiry' do
      allow(Redis::Alfred).to receive(:set)

      described_class.mark!(actor_key)

      expect(Redis::Alfred).to have_received(:set).with(redis_key, kind_of(Integer), ex: 60)
    end

    it 'does not write without an actor' do
      expect(Redis::Alfred).not_to receive(:set)

      described_class.mark!(nil)
    end
  end
end
