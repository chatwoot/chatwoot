# frozen_string_literal: true

require_relative "../spec_helper"
require "minitest/stub_const"

describe "Cache store config when using fail2ban" do
  before do
    Rack::Attack.blocklist("fail2ban pentesters") do |request|
      Rack::Attack::Fail2Ban.filter(request.ip, maxretry: 2, findtime: 30, bantime: 60) do
        request.path.include?("private-place")
      end
    end
  end

  it "gives semantic error if no store was configured" do
    assert_raises(Rack::Attack::MissingStoreError) do
      get "/private-place"
    end
  end

  it "gives semantic error if store is missing #read method" do
    raised_exception = nil

    fake_store_class = Class.new do
      def write(key, value); end

      def increment(key, count, options = {}); end
    end

    Object.stub_const(:FakeStore, fake_store_class) do
      Rack::Attack.cache.store = FakeStore.new

      raised_exception = assert_raises(Rack::Attack::MisconfiguredStoreError) do
        get "/private-place"
      end
    end

    assert_equal "Configured store FakeStore doesn't respond to #read method", raised_exception.message
  end

  it "gives semantic error if store is missing #write method" do
    raised_exception = nil

    fake_store_class = Class.new do
      def read(key); end

      def increment(key, count, options = {}); end
    end

    Object.stub_const(:FakeStore, fake_store_class) do
      Rack::Attack.cache.store = FakeStore.new

      raised_exception = assert_raises(Rack::Attack::MisconfiguredStoreError) do
        get "/private-place"
      end
    end

    assert_equal "Configured store FakeStore doesn't respond to #write method", raised_exception.message
  end

  it "gives semantic error if store is missing #increment method" do
    raised_exception = nil

    fake_store_class = Class.new do
      def read(key); end

      def write(key, value); end
    end

    Object.stub_const(:FakeStore, fake_store_class) do
      Rack::Attack.cache.store = FakeStore.new

      raised_exception = assert_raises(Rack::Attack::MisconfiguredStoreError) do
        get "/private-place"
      end
    end

    assert_equal "Configured store FakeStore doesn't respond to #increment method", raised_exception.message
  end

  it "works with any object that responds to #read, #write and #increment" do
    FakeStore = Class.new do
      attr_accessor :backend

      def initialize
        @backend = {}
      end

      def read(key)
        @backend[key]
      end

      def write(key, value, _options = {})
        @backend[key] = value
      end

      def increment(key, _count, _options = {})
        @backend[key] ||= 0
        @backend[key] += 1
      end
    end

    Rack::Attack.cache.store = FakeStore.new

    get "/"
    assert_equal 200, last_response.status

    get "/private-place"
    assert_equal 403, last_response.status

    get "/private-place"
    assert_equal 403, last_response.status

    get "/"
    assert_equal 403, last_response.status
  end
end
