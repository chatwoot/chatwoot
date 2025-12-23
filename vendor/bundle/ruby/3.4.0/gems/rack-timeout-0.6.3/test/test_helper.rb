require "test/unit"
require "rack/test"
require "rack-timeout"

class RackTimeoutTest < Test::Unit::TestCase
  include Rack::Test::Methods

  attr_accessor :settings

  def initialize(*args)
    self.settings ||= {}
    super(*args)
  end

  def app
    settings = self.settings
    Rack::Builder.new do
      use Rack::Timeout, **settings

      map "/" do
        run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['OK']] }
      end

      map "/sleep" do
        run lambda { |env| sleep }
      end
    end
  end

  # runs the test with the given environment, but doesnt restore the original
  # environment afterwards. This should be sufficient for rack-timeout testing.
  def with_env(hash)
    hash.each_pair do |k, v|
      ENV[k.to_s] = v.to_s
    end
    yield
    hash.each_key do |k|
      ENV[k.to_s] = nil
    end
  end

  def time_in_msec(t = Time.now)
    "#{t.tv_sec}#{t.tv_usec/1000}"
  end
end
