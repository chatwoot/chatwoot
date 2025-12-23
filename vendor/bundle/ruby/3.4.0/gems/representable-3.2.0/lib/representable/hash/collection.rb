require 'representable/hash'

module Representable::Hash
  module Collection
    include Representable::Hash

    def self.included(base)
      base.class_eval do
        include Representable::Hash
        extend ClassMethods
        property(:_self, {:collection => true})
      end
    end


    module ClassMethods
      def items(options={}, &block)
        collection(:_self, options.merge(:getter => lambda { |*| self }), &block)
      end
    end

    # TODO: revise lonely collection and build separate pipeline where we just use Serialize, etc.

    def create_representation_with(doc, options, format)
      options = normalize_options(**options)
      options[:_self] = options

      bin   = representable_bindings_for(format, options).first

      Collect[*bin.default_render_fragment_functions].
        (represented, {doc: doc, fragment: represented, options: options, binding: bin, represented: represented})
    end

    def update_properties_from(doc, options, format)
      options = normalize_options(**options)
      options[:_self] = options

      bin   = representable_bindings_for(format, options).first

      value = Collect[*bin.default_parse_fragment_functions].
        (doc, fragment: doc, document: doc, options: options, binding: bin, represented: represented)

      represented.replace(value)
    end
  end
end
