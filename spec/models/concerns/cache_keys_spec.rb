require 'rails_helper'

RSpec.describe CacheKeys do
  let(:test_model) do
    Struct.new(:id) do
      include CacheKeys

      def fetch_value_for_key(_id, _key)
        'value'
      end
    end.new(1)
  end

  before do
    allow(Redis::Alfred).to receive(:delete)
    allow(Redis::Alfred).to receive(:set)
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
  end

  describe '#cache_keys' do
    it 'returns a hash of cache keys' do
      expected_keys = test_model.class.cacheable_models.map do |model|
        [model.name.underscore.to_sym, 'value']
      end.to_h

      expect(test_model.cache_keys).to eq(expected_keys)
    end
  end

  describe '#invalidate_cache_key_for' do
    it 'deletes the cache key' do
      test_model.invalidate_cache_key_for('label')
      expect(Redis::Alfred).to have_received(:delete).with('idb-cache-key-account-1-label')
    end

    it 'dispatches a cache update event' do
      test_model.invalidate_cache_key_for('label')
      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
        CacheKeys::ACCOUNT_CACHE_INVALIDATED,
        kind_of(ActiveSupport::TimeWithZone),
        cache_keys: test_model.cache_keys,
        account: test_model
      )
    end
  end

  describe '#update_cache_key' do
    it 'updates the cache key' do
      allow(Time).to receive(:now).and_return(Time.parse('2023-05-29 00:00:00 UTC'))
      test_model.update_cache_key('label')
      expect(Redis::Alfred).to have_received(:set).with('idb-cache-key-account-1-label', Time.now.utc.to_i)
    end

    it 'dispatches a cache update event' do
      test_model.update_cache_key('label')
      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
        CacheKeys::ACCOUNT_CACHE_INVALIDATED,
        kind_of(ActiveSupport::TimeWithZone),
        cache_keys: test_model.cache_keys,
        account: test_model
      )
    end
  end

  describe '#reset_cache_keys' do
    it 'invalidates all cache keys for cacheable models' do
      test_model.reset_cache_keys
      test_model.class.cacheable_models.each do |model|
        expect(Redis::Alfred).to have_received(:delete).with("idb-cache-key-account-1-#{model.name.underscore}")
      end
    end
  end
end
