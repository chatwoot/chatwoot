require "declarative/definitions"
require "declarative/defaults"
require "declarative/variables"
require "declarative/heritage"

module Declarative
  # Include this to maintain inheritable, nested schemas with ::defaults and
  # ::feature the way we have it in Representable, Reform, and Disposable.
  #
  # The schema with its defnitions will be kept in ::definitions.
  #
  # Requirements to includer: ::default_nested_class, override building with ::nested_builder.
  module Schema
    def self.extended(extender)
      extender.extend DSL                 # ::property
      extender.extend Feature             # ::feature
      extender.extend Heritage::DSL       # ::heritage
      extender.extend Heritage::Inherited # ::included
    end

    module DSL
      def property(name, options={}, &block)
        heritage.record(:property, name, options, &block)

        build_definition(name, options, &block)
      end

      def defaults(options={}, &block)
        heritage.record(:defaults, options, &block)

        # Always convert arrays to Variables::Append instructions.
        options = options.merge( Defaults.wrap_arrays(options) )
        block   = wrap_arrays_from_block(block) if block_given?

        _defaults.merge!(options, &block)
      end

      def definitions
        @definitions ||= Definitions.new(definition_class)
      end

      def definition_class # TODO: test me.
        Definitions::Definition
      end

    private
      def build_definition(name, options={}, &block)
        default_options = {
            _base: default_nested_class,
            _defaults: _defaults
        }
        default_options[:_nested_builder] = nested_builder if block

        # options = options.merge( Defaults.wrap_arrays(options) )

        definitions.add(name, default_options.merge(options), &block)
      end

      def _defaults
        @defaults ||= Declarative::Defaults.new
      end

      def nested_builder
        NestedBuilder # default implementation.
      end

      NestedBuilder = ->(options) do
        Class.new(options[:_base]) do # base
          feature(*options[:_features])
          class_eval(&options[:_block])
        end
      end

      # When called, executes `block` and wraps all array values in Variables::Append.
      # This is the default behavior in older versions and allows to provide arrays for
      # default values that will be prepended.
      def wrap_arrays_from_block(block)
        ->(*args) {
          options = block.(*args)
          options.merge( Defaults.wrap_arrays( options ) )
        }
      end
    end

    module Feature
      # features are registered as defaults using _features, which in turn get translated to
      # Class.new... { feature mod } which makes it recursive in nested schemas.
      def feature(*mods)
        mods.each do |mod|
          include mod
          register_feature(mod)
        end
      end

    private
      def register_feature(mod)
        heritage.record(:register_feature, mod) # this is only for inheritance between decorators and modules!!! ("horizontal and vertical")

        defaults.merge!( _features: Variables::Append([mod]) )
      end
    end
  end
end
