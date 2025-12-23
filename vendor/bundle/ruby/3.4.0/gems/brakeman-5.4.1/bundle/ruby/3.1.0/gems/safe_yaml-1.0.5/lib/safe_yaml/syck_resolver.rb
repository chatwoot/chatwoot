module SafeYAML
  class SyckResolver < Resolver
    QUOTE_STYLES = [
      :quote1,
      :quote2
    ].freeze

    NODE_TYPES = {
      Hash   => :map,
      Array  => :seq,
      String => :scalar
    }.freeze

    def initialize(options={})
      super
    end

    def native_resolve(node)
      node.transform(self.options)
    end

    def get_node_type(node)
      NODE_TYPES[node.value.class]
    end

    def get_node_tag(node)
      node.type_id
    end

    def get_node_value(node)
      node.value
    end

    def value_is_quoted?(node)
      QUOTE_STYLES.include?(node.instance_variable_get(:@style))
    end
  end
end
