# frozen_string_literal: true

require_relative "../../spec_helper"

if defined?(::Dalli)
  require_relative "../../support/cache_store_helper"
  require "dalli"
  require "timecop"

  describe "Dalli::Client as a cache backend" do
    before do
      Rack::Attack.cache.store = Dalli::Client.new
    end

    after do
      Rack::Attack.cache.store.flush_all
    end

    it_works_for_cache_backed_features(fetch_from_store: ->(key) { Rack::Attack.cache.store.fetch(key) })
  end
end
