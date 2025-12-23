require 'test_helper'
require File.join(File.dirname(__FILE__), 'stubs')

module ScoutApm
module LayerConverters
class MetricConverterTest < Minitest::Test
  include Stubs

  def test_register_adds_hooks
    mc = MetricConverter.new(agent_context, faux_request, faux_layer_finder, faux_store)
    faux_walker.expects(:on)
    mc.register_hooks(faux_walker)
  end

  def test_record
    mc = MetricConverter.new(agent_context, faux_request, faux_layer_finder, faux_store)
    faux_store.expects(:track!)
    mc.record!
  end
end
end
end
