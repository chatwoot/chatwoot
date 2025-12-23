module SafeYAML
  class PsychResolver < Resolver
    NODE_TYPES = {
      Psych::Nodes::Document => :root,
      Psych::Nodes::Mapping  => :map,
      Psych::Nodes::Sequence => :seq,
      Psych::Nodes::Scalar   => :scalar,
      Psych::Nodes::Alias    => :alias
    }.freeze

    def initialize(options={})
      super
      @aliased_nodes = {}
    end

    def resolve_root(root)
      resolve_seq(root).first
    end

    def resolve_alias(node)
      resolve_node(@aliased_nodes[node.anchor])
    end

    def native_resolve(node)
      @visitor ||= SafeYAML::SafeToRubyVisitor.new(self)
      @visitor.accept(node)
    end

    def get_node_type(node)
      NODE_TYPES[node.class]
    end

    def get_node_tag(node)
      node.tag
    end

    def get_node_value(node)
      @aliased_nodes[node.anchor] = node if node.respond_to?(:anchor) && node.anchor

      case get_node_type(node)
      when :root, :map, :seq
        node.children
      when :scalar
        node.value
      end
    end

    def value_is_quoted?(node)
      node.quoted
    end
  end
end
