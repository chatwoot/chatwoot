$:.unshift File.expand_path('../../lib', __FILE__)
require 'stackprof'
require 'minitest/autorun'

if RUBY_ENGINE == 'truffleruby'
  class StackProfTruffleRubyTest < MiniTest::Test
    def test_error
      error = assert_raises RuntimeError do
        StackProf.run(mode: :cpu) do
          unreacheable
        end
      end

      assert_match(/TruffleRuby/, error.message)
      assert_match(/--cpusampler/, error.message)
    end
  end
end
