# frozen_string_literal: true

require_relative "../../spec_helper"
require_relative "../../support/cache_store_helper"

if defined?(::Redis::Store)
  require "timecop"

  describe "ActiveSupport::Cache::RedisStore as a cache backend" do
    before do
      Rack::Attack.cache.store = ::Redis::Store.new
    end

    after do
      Rack::Attack.cache.store.flushdb
    end

    it_works_for_cache_backed_features(fetch_from_store: ->(key) { Rack::Attack.cache.store.read(key) })
  end
end
