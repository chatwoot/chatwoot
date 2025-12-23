# frozen_string_literal: true

module RuboCop
  # Find duplicated keys from YAML.
  # @api private
  module YAMLDuplicationChecker
    def self.check(yaml_string, filename, &on_duplicated)
      handler = DuplicationCheckHandler.new(&on_duplicated)
      parser = Psych::Parser.new(handler)
      parser.parse(yaml_string, filename)
      parser.handler.root.children[0]
    end

    class DuplicationCheckHandler < Psych::TreeBuilder # :nodoc:
      def initialize(&block)
        super()
        @block = block
      end

      def end_mapping
        mapping_node = super
        # OPTIMIZE: Use a hash for faster lookup since there can
        # be quite a few keys at the top-level.
        keys = {}
        mapping_node.children.each_slice(2) do |key, _value|
          duplicate = keys[key.value]
          @block.call(duplicate, key) if duplicate
          keys[key.value] = key
        end
        mapping_node
      end
    end
  end
end
