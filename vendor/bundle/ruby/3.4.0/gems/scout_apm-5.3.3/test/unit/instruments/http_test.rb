if (ENV["SCOUT_TEST_FEATURES"] || "").include?("instruments")
  require 'test_helper'

  require 'scout_apm/instruments/http'

  require 'http'

  class HttpTest < Minitest::Test
    def setup
      @context = ScoutApm::AgentContext.new
      @instance = ScoutApm::Instruments::HTTP.new(@context)
      @instrument_manager = ScoutApm::InstrumentManager.new(@context)
      @instance.install(prepend: @instrument_manager.prepend_for_instrument?(@instance.class))
    end

    def test_installs_using_proper_method
      if @instrument_manager.prepend_for_instrument?(@instance.class) == true
        assert ::HTTP::Client.ancestors.include?(ScoutApm::Instruments::HTTPInstrumentationPrepend)
      else
        assert_equal false, ::HTTP::Client.ancestors.include?(ScoutApm::Instruments::HTTPInstrumentationPrepend)
      end
    end
  end
end