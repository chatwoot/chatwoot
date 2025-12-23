require 'representable/hash/binding'

module Representable
  module YAML
    class Binding < Representable::Hash::Binding
      def self.build_for(definition)
        return Collection.new(definition) if definition.array?

        new(definition)
      end

      def write(map, fragment, as)
        map.children << Psych::Nodes::Scalar.new(as)
        map.children << node_for(fragment)  # FIXME: should be serialize.
      end
    # private

      def node_for(fragment)
        write_scalar(fragment)
      end

      def write_scalar(value)
        return value if typed?

        Psych::Nodes::Scalar.new(value.to_s)
      end

      def serialize_method
        :to_ast
      end

      def deserialize_method
        :from_hash
      end


      class Collection < self
        include Representable::Binding::Collection

        def node_for(fragments)
          Psych::Nodes::Sequence.new.tap do |seq|
            seq.style = Psych::Nodes::Sequence::FLOW if self[:style] == :flow
            fragments.each { |frag| seq.children << write_scalar(frag) }
          end
        end
      end
    end
  end
end
