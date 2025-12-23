if (ENV["SCOUT_TEST_FEATURES"] || "").include?("typhoeus")
  require 'test_helper'

  require 'scout_apm/instruments/typhoeus'

  require 'typhoeus'

  class TyphoeusTest < Minitest::Test
    def setup
      @context = ScoutApm::AgentContext.new
      @recorder = FakeRecorder.new
      ScoutApm::Agent.instance.context.recorder = @recorder
      ScoutApm::Instruments::Typhoeus.new(@context).install(prepend: false)
    end

    def test_instruments_typhoeus_hydra
      hydra = Typhoeus::Hydra.new
      2.times.map{ hydra.queue(Typhoeus::Request.new("example.com", followlocation: true)) }

      assert_equal "2 requests", hydra.scout_desc

      hydra.run
      assert_equal "0 requests", hydra.scout_desc
      assert_recorded(@recorder, "HTTP", "Hydra", "2 requests")
    end

    def test_instruments_typhoeus
      Typhoeus.get("example.com", followlocation: true)
      assert_recorded(@recorder, "HTTP", "get", "example.com")
    end

    private

    def assert_recorded(recorder, type, name, desc = nil)
      req = recorder.requests.first
      assert req, "recorder recorded no layers"
      assert_equal type, req.root_layer.type
      assert_equal name, req.root_layer.name
      assert_equal desc, req.root_layer.desc if !desc.nil?
    end
  end
end