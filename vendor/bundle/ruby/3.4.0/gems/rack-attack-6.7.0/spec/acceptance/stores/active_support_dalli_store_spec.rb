# frozen_string_literal: true

require_relative "../../spec_helper"

should_run =
  defined?(::Dalli) &&
  Gem::Version.new(::Dalli::VERSION) < Gem::Version.new("3")

if should_run
  require_relative "../../support/cache_store_helper"
  require "active_support/cache/dalli_store"
  require "timecop"

  describe "ActiveSupport::Cache::DalliStore as a cache backend" do
    before do
      Rack::Attack.cache.store = ActiveSupport::Cache::DalliStore.new
    end

    after do
      Rack::Attack.cache.store.clear
    end

    it_works_for_cache_backed_features(fetch_from_store: ->(key) { Rack::Attack.cache.store.fetch(key) })
  end
end
