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
    it 'returns the zero epoch time if no value is cached' do
      result = helper.fetch_value_for_key(account_id, 'another-key')

      expect(result).to eq('0000000000000')
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
