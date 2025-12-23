module Sass::Script::Tree
  # A class representing a map literal. When resolved, this returns a
  # {Sass::Script::Node::Map}.
  class MapLiteral < Node
    # The key/value pairs that make up this map node. This isn't a Hash so that
    # we can detect key collisions once all the keys have been performed.
    #
    # @return [Array<(Node, Node)>]
    attr_reader :pairs

    # Creates a new map literal.
    #
    # @param pairs [Array<(Node, Node)>] See \{#pairs}
    def initialize(pairs)
      @pairs = pairs
    end

    # @see Node#children
    def children
      @pairs.flatten
    end

    # @see Node#to_sass
    def to_sass(opts = {})
      return "()" if pairs.empty?

      to_sass = lambda do |value|
        if value.is_a?(ListLiteral) && value.separator == :comma
          "(#{value.to_sass(opts)})"
        else
          value.to_sass(opts)
        end
      end

      "(" + pairs.map {|(k, v)| "#{to_sass[k]}: #{to_sass[v]}"}.join(', ') + ")"
    end
    alias_method :inspect, :to_sass

    # @see Node#deep_copy
    def deep_copy
      node = dup
      node.instance_variable_set('@pairs',
        pairs.map {|(k, v)| [k.deep_copy, v.deep_copy]})
      node
    end

    protected

    # @see Node#_perform
    def _perform(environment)
      keys = Set.new
      map = Sass::Script::Value::Map.new(Hash[pairs.map do |(k, v)|
        k, v = k.perform(environment), v.perform(environment)
        if keys.include?(k)
          raise Sass::SyntaxError.new("Duplicate key #{k.inspect} in map #{to_sass}.")
        end
        keys << k
        [k, v]
      end])
      map.options = options
      map
    end
  end
end
