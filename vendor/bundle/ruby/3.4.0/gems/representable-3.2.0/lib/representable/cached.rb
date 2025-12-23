module Representable
  # Using this module only makes sense with Decorator representers.
  module Cached
    module BuildDefinition
      def build_definition(*)
        super.tap do |definition|
          binding_builder = format_engine::Binding

          map << binding_builder.build(definition)
        end
      end
    end

    def self.included(includer)
      includer.extend(BuildDefinition)
    end

    def representable_map(*)
      self.class.map
    end
  end
end
