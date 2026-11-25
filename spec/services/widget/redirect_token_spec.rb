require 'rails_helper'

RSpec.describe Widget::RedirectToken do
  let(:payload) { { 'identifier' => 'user-123', 'message' => 'Hello there' } }

  describe '.generate' do
    it 'stores the payload in Redis and returns a token' do
      token = described_class.generate(payload)

      expect(token).to be_present
      expect(described_class.consume(token)).to eq(payload)
    end

    it 'honours a custom ttl' do
      token = described_class.generate(payload, ttl: 120)
      key = "#{described_class::KEY_PREFIX}::#{token}"

      expect(Redis::Alfred.ttl(key)).to be_within(5).of(120)
    end

    it 'defaults to a 24 hour ttl' do
      token = described_class.generate(payload)
      key = "#{described_class::KEY_PREFIX}::#{token}"

      expect(Redis::Alfred.ttl(key)).to be_within(5).of(24.hours.to_i)
    end
  end

  describe '.consume' do
    it 'returns the stored payload' do
      token = described_class.generate(payload)

      expect(described_class.consume(token)).to eq(payload)
    end

    it 'deletes the token so it can only be consumed once' do
      token = described_class.generate(payload)

      expect(described_class.consume(token)).to eq(payload)
      expect(described_class.consume(token)).to be_nil
    end

    it 'returns nil for a blank token' do
      expect(described_class.consume(nil)).to be_nil
      expect(described_class.consume('')).to be_nil
    end

    it 'returns nil for an unknown token' do
      expect(described_class.consume('does-not-exist')).to be_nil
    end
  end
end
