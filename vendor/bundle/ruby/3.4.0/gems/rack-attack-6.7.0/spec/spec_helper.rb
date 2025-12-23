# frozen_string_literal: true

require "bundler/setup"

require "minitest/autorun"
require "minitest/pride"
require "rack/test"
require "active_support"
require "rack/attack"

if RUBY_ENGINE == "ruby"
  require "byebug"
end

def safe_require(name)
  require name
rescue LoadError
  nil
end

safe_require "connection_pool"
safe_require "dalli"
safe_require "redis"
safe_require "redis-activesupport"
safe_require "redis-store"

class MiniTest::Spec
  include Rack::Test::Methods

  before do
    if Object.const_defined?(:Rails) && Rails.respond_to?(:cache)
      Rails.cache.clear
    end
  end

  after do
    Rack::Attack.clear_configuration
    Rack::Attack.instance_variable_set(:@cache, nil)
  end

  def app
    Rack::Builder.new do
      # Use Rack::Lint to test that rack-attack is complying with the rack spec
      use Rack::Lint
      # Intentionally added twice to test idempotence property
      use Rack::Attack
      use Rack::Attack
      use Rack::Lint

      run lambda { |_env| [200, {}, ['Hello World']] }
    end.to_app
  end

  def self.it_allows_ok_requests
    it "must allow ok requests" do
      get '/', {}, 'REMOTE_ADDR' => '127.0.0.1'

      _(last_response.status).must_equal 200
      _(last_response.body).must_equal 'Hello World'
    end
  end
end

class Minitest::SharedExamples < Module
  include Minitest::Spec::DSL
end
