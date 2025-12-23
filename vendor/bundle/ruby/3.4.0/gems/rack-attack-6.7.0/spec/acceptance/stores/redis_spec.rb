# frozen_string_literal: true

require_relative "../../spec_helper"

if defined?(::Redis)
  require_relative "../../support/cache_store_helper"
  require "timecop"

  describe "Plain redis as a cache backend" do
    before do
      Rack::Attack.cache.store = Redis.new
    end

    after do
      Rack::Attack.cache.store.flushdb
    end

    it_works_for_cache_backed_features(fetch_from_store: ->(key) { Rack::Attack.cache.store.get(key) })
  end
end
