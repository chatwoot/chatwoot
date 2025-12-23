module SafeYAML
  class Resolver
    def initialize(options)
      @options              = SafeYAML::OPTIONS.merge(options || {})
      @whitelist            = @options[:whitelisted_tags] || []
      @initializers         = @options[:custom_initializers] || {}
      @raise_on_unknown_tag = @options[:raise_on_unknown_tag]
    end

    def resolve_node(node)
      return node if !node
      return self.native_resolve(node) if tag_is_whitelisted?(self.get_node_tag(node))

      case self.get_node_type(node)
      when :root
        resolve_root(node)
      when :map
        resolve_map(node)
      when :seq
        resolve_seq(node)
      when :scalar
        resolve_scalar(node)
      when :alias
        resolve_alias(node)
      else
        raise "Don't know how to resolve this node: #{node.inspect}"
      end
    end

    def resolve_map(node)
      tag  = get_and_check_node_tag(node)
      hash = @initializers.include?(tag) ? @initializers[tag].call : {}
      map  = normalize_map(self.get_node_value(node))

      # Take the "<<" key nodes first, as these are meant to approximate a form of inheritance.
      inheritors = map.select { |key_node, value_node| resolve_node(key_node) == "<<" }
      inheritors.each do |key_node, value_node|
        merge_into_hash(hash, resolve_node(value_node))
      end

      # All that's left should be normal (non-"<<") nodes.
      (map - inheritors).each do |key_node, value_node|
        hash[resolve_node(key_node)] = resolve_node(value_node)
      end

      return hash
    end

    def resolve_seq(node)
      seq = self.get_node_value(node)

      tag = get_and_check_node_tag(node)
      arr = @initializers.include?(tag) ? @initializers[tag].call : []

      seq.inject(arr) { |array, n| array << resolve_node(n) }
    end

    def resolve_scalar(node)
      Transform.to_proper_type(self.get_node_value(node), self.value_is_quoted?(node), get_and_check_node_tag(node), @options)
    end

    def get_and_check_node_tag(node)
      tag = self.get_node_tag(node)
      SafeYAML.tag_safety_check!(tag, @options)
      tag
    end

    def tag_is_whitelisted?(tag)
      @whitelist.include?(tag)
    end

    def options
      @options
    end

    private
    def normalize_map(map)
      # Syck creates Hashes from maps.
      if map.is_a?(Hash)
        map.inject([]) { |arr, key_and_value| arr << key_and_value }

      # Psych is really weird; it flattens out a Hash completely into: [key, value, key, value, ...]
      else
        map.each_slice(2).to_a
      end
    end

    def merge_into_hash(hash, array)
      array.each do |key, value|
        hash[key] = value
      end
    end
  end
end
