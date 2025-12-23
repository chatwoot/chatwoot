require 'representable/binding'

module Representable
  module Object
    class Binding < Representable::Binding
      def self.build_for(definition)  # TODO: remove default arg.
        return Collection.new(definition)  if definition.array?

        new(definition)
      end

      def read(hash, as)
        fragment = hash.send(as) # :getter? no, that's for parsing!

        return FragmentNotFound if fragment.nil? and typed?

        fragment
      end

      def write(hash, fragment, as)
        true
      end

      def deserialize_method
        :from_object
      end

      def serialize_method
        :to_object
      end


      class Collection < self
        include Representable::Binding::Collection
      end
    end
  end
end
