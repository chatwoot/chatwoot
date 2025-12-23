require "declarative/schema"

module Representable
  autoload :Decorator, "representation/decorator"
  autoload :Definition, "representation/definition"

  module Declarative
    def representation_wrap=(name)
      heritage.record(:representation_wrap=, name)

      definitions.wrap = name
    end

    def collection(name, options={}, &block)
      property(name, options.merge(collection: true), &block)
    end

    def hash(name=nil, options={}, &block)
      return super() unless name  # allow Object.hash.

      options[:hash] = true
      property(name, options, &block)
    end

    # Allows you to nest a block of properties in a separate section while still mapping
    # them to the original object.
    def nested(name, options={}, &block)
      options = options.merge(
        getter:   ->(_opts) { self },
        setter:   ->(opts) { },
        instance: ->(_opts) { self },
      )

      if block
        options[:_nested_builder] = Decorator.nested_builder
        options[:_base]           = Decorator.default_nested_class
      end

      property(name, options, &block)
    end


    include ::Declarative::Schema::DSL # ::property
    include ::Declarative::Schema::Feature
    include ::Declarative::Heritage::DSL

    def default_nested_class
      Module.new # FIXME: make that unnecessary in Declarative
    end


    NestedBuilder = ->(options) do
      Module.new do
        include Representable # FIXME: do we really need this?
        feature(*options[:_features])
        include(*options[:_base]) # base when :inherit, or in decorator.

        module_eval(&options[:_block])
      end
    end

    def nested_builder
      NestedBuilder
    end

    def definitions
      @definitions ||= Config.new(Representable::Definition)
    end

    alias_method :representable_attrs, :definitions
  end
end
