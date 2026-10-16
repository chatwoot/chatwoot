require 'rails_helper'

RSpec.describe CacheKeysHelper do
  let(:account_id) { 1 }
  let(:key) { 'example_key' }

  describe '#get_prefixed_cache_key' do
    it 'returns a string with the correct prefix, account ID, and key' do
      expected_key = "idb-cache-key-account-#{account_id}-#{key}"
      result = helper.get_prefixed_cache_key(account_id, key)

      expect(result).to eq(expected_key)
    end
  end

  describe '#fetch_value_for_key' do
    it 'starts a fresh expiring value if no value is cached' do
      result = helper.fetch_value_for_key(account_id, 'another-key')
      prefixed_cache_key = helper.get_prefixed_cache_key(account_id, 'another-key')

      expect(result).to match(/\A\d{13}\z/)
      expect(helper.fetch_value_for_key(account_id, 'another-key')).to eq(result)
      expect(Redis::Alfred.get(prefixed_cache_key)).to eq(result)
      expect(Redis::Alfred.ttl(prefixed_cache_key)).to be_between(1, CacheKeys::CACHE_KEYS_EXPIRY.to_i)
    end

    it 'does not hand out the same value again after the key expires' do
      first_value = helper.fetch_value_for_key(account_id, 'expiring-key')
      Redis::Alfred.delete(helper.get_prefixed_cache_key(account_id, 'expiring-key'))

      travel 1.second do
        expect(helper.fetch_value_for_key(account_id, 'expiring-key')).not_to eq(first_value)
      end
    end

    it 'returns a cached value if it exists' do
      value = Time.now.to_i
      prefixed_cache_key = helper.get_prefixed_cache_key(account_id, key)

      Redis::Alfred.set(prefixed_cache_key, value)

      result = helper.fetch_value_for_key(account_id, key)

      expect(result).to eq(value.to_s)
    end
  end
end
