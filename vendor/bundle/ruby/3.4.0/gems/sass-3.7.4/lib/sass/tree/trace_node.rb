require 'sass/tree/node'

module Sass::Tree
  # A solely static node left over after a mixin include or @content has been performed.
  # Its sole purpose is to wrap exceptions to add to the backtrace.
  #
  # @see Sass::Tree
  class TraceNode < Node
    # The name of the trace entry to add.
    #
    # @return [String]
    attr_reader :name

    # @param name [String] The name of the trace entry to add.
    def initialize(name)
      @name = name
      self.has_children = true
      super()
    end

    # Initializes this node from an existing node.
    # @param name [String] The name of the trace entry to add.
    # @param node [Node] The node to copy information from.
    # @return [TraceNode]
    def self.from_node(name, node)
      trace = new(name)
      trace.line = node.line
      trace.filename = node.filename
      trace.options = node.options
      trace
    end
  end
end
