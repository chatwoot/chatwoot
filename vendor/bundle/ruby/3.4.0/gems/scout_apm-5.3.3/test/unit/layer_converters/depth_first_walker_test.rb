require 'test_helper'

module ScoutApm
class DepthFirstWalkerTest < Minitest::Test
  def test_walk_single_node_calls_callbacks_in_order
    calls = []
    layer = Layer.new("A", "x")

    walker = LayerConverters::DepthFirstWalker.new(layer)
    walker.before { |l| calls << :before }
    walker.after { |l| calls << :after }
    walker.on { |l| calls << :on }

    walker.walk

    assert_equal [:before, :on, :after], calls
  end

  # Tree looks like:
  #    A
  #    |
  #    B
  #  / \ \
  #  C  D E
  # / \
  # F  G
  def test_walk_interesting_tree
    # The test could be rewritten to support 1.8.7, but it would likely be much
    # harder to read.
    skip "Lack of set ordering in Ruby 1.8.7 prevents this test from running correctly" if RUBY_VERSION.start_with?("1.8.")

    calls = []
    a = Layer.new("A", "x")
    b = Layer.new("B", "x")
    c = Layer.new("C", "x")
    d = Layer.new("D", "x")
    e = Layer.new("E", "x")
    f = Layer.new("F", "x")
    g = Layer.new("G", "x")
    a.add_child(b)
    b.add_child(c)
    b.add_child(d)
    b.add_child(e)
    c.add_child(f)
    c.add_child(g)

    root_layer = a

    walker = LayerConverters::DepthFirstWalker.new(root_layer)
    walker.before { |l| calls << "#{l.type} before" }
    walker.after { |l| calls << "#{l.type} after" }
    walker.on { |l| calls << "#{l.type} on" }

    walker.walk

    assert_equal [
      "A before", "A on", # before & on always line up next to each other
      "B before", "B on",
      "C before", "C on",
      "F before", "F on", "F after", # leaf nodes run all 3
      "G before", "G on", "G after",
      "C after", # once all children are done, do a node's after
      "D before", "D on", "D after",
      "E before", "E on", "E after",
      "B after",
      "A after"
    ], calls
  end
end
end
