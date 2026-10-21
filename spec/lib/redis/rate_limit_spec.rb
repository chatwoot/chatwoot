require 'rails_helper'

RSpec.describe Redis::RateLimit do
  let(:key) { "RATE_LIMIT_SPEC::#{SecureRandom.hex(4)}" }
  let(:rate_limit) { described_class.new(key, limit: 2, window: 1.hour) }

  after { Redis::Alfred.delete(key) }

  describe '#exceeded?' do
    it 'counts every call and is exceeded once the count passes the limit' do
      expect([rate_limit.exceeded?, rate_limit.exceeded?, rate_limit.exceeded?]).to eq([false, false, true])
    end

    it 'sets the expiry on the first hit' do
      rate_limit.exceeded?

      expect(Redis::Alfred.ttl(key)).to be_between(3590, 3600)
    end

    it 'does not move the expiry on later hits' do
      rate_limit.exceeded?
      Redis::Alfred.expire(key, 60)

      rate_limit.exceeded?

      expect(Redis::Alfred.ttl(key)).to be <= 60
    end

    it 'sets the expiry on a counter that has none' do
      Redis::Alfred.incr(key)

      rate_limit.exceeded?

      expect(Redis::Alfred.ttl(key)).to be_between(3590, 3600)
    end
  end

  describe '#remaining' do
    it 'is the limit before any hit' do
      expect(rate_limit.remaining).to eq(2)
    end

    it 'goes down with each hit and never below zero' do
      rate_limit.exceeded?
      expect(rate_limit.remaining).to eq(1)

      2.times { rate_limit.exceeded? }
      expect(rate_limit.remaining).to eq(0)
    end
  end
end
