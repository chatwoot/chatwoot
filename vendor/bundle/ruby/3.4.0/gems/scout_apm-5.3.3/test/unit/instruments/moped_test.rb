if (ENV["SCOUT_TEST_FEATURES"] || "").include?("instruments")
  require 'test_helper'

  require 'scout_apm/instruments/moped'

  require 'moped'

  class MopedTest < Minitest::Test
    def setup
      @context = ScoutApm::AgentContext.new
      @instance = ScoutApm::Instruments::Moped.new(@context)
      @instrument_manager = ScoutApm::InstrumentManager.new(@context)
      @instance.install(prepend: @instrument_manager.prepend_for_instrument?(@instance.class))
    end

    def test_installs_using_proper_method
      if @instrument_manager.prepend_for_instrument?(@instance.class) == true
        assert ::Moped::Node.ancestors.include?(ScoutApm::Instruments::MopedInstrumentationPrepend)
      else
        assert_equal false, ::Moped::Node.ancestors.include?(ScoutApm::Instruments::MopedInstrumentationPrepend)
      end
    end
  end
end