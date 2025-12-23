if (ENV["SCOUT_TEST_FEATURES"] || "").include?("instruments")
  require 'test_helper'

  require 'scout_apm/instruments/http_client'

  require 'httpclient'

  class HttpClientTest < Minitest::Test
    def setup
      @context = ScoutApm::AgentContext.new
      @instance = ScoutApm::Instruments::HttpClient.new(@context)
      @instrument_manager = ScoutApm::InstrumentManager.new(@context)
      @instance.install(prepend: @instrument_manager.prepend_for_instrument?(@instance.class))
    end

    def test_installs_using_proper_method
      if @instrument_manager.prepend_for_instrument?(@instance.class) == true
        assert ::HTTPClient.ancestors.include?(ScoutApm::Instruments::HttpClientInstrumentationPrepend)
      else
        assert_equal false, ::HTTPClient.ancestors.include?(ScoutApm::Instruments::HttpClientInstrumentationPrepend)
      end
    end
  end
end