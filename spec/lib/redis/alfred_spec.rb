require 'rails_helper'

RSpec.describe Redis::Alfred do
  describe '.delete_if_equals' do
    let(:key) { "alfred-spec:#{SecureRandom.hex(16)}" }

    after { described_class.delete(key) }

    it 'returns true when the matching value is deleted' do
      described_class.set(key, 'owner')

      expect(described_class.delete_if_equals(key, 'owner')).to be true
      expect(described_class.get(key)).to be_nil
    end

    it 'returns false without deleting a different value' do
      described_class.set(key, 'other-owner')

      expect(described_class.delete_if_equals(key, 'owner')).to be false
      expect(described_class.get(key)).to eq('other-owner')
    end

    it 'returns false when the key has already been deleted' do
      expect(described_class.delete_if_equals(key, 'owner')).to be false
    end

    it 'returns false when the watched transaction aborts' do
      described_class.set(key, 'owner')
      described_class.with do |connection|
        allow(connection).to receive(:multi) do
          connection.unwatch
          nil
        end

        expect(described_class.delete_if_equals(key, 'owner')).to be false
      end
      expect(described_class.get(key)).to eq('owner')
    end
  end
end
