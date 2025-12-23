require "uber/inheritable_attr"
require "representable"

module Representable
  class Decorator
    attr_reader :represented
    alias_method :decorated, :represented

    # TODO: when moving all class methods into ClassMethods, i get a segfault.
    def self.prepare(represented)
      new(represented)
    end

    def self.default_nested_class #FIXME. SHOULD we move that into NestedBuilder?
      Representable::Decorator
    end

    # extend ::Declarative::Heritage::Inherited # DISCUSS: currently, that is handled via Representable::inherited.

    # This is called from inheritable_attr when inheriting a decorator class to a subclass.
    # Explicitly subclassing the Decorator makes sure representable_attrs is a clean version.
    def self.clone
      Class.new(self)
    end

    include Representable # include after class methods so Decorator::prepare can't be overwritten by Representable::prepare.
    include Cached

    extend Uber::InheritableAttr
    inheritable_attr :map
    self.map = Binding::Map.new

    def initialize(represented)
      @represented = represented
    end

    def self.nested_builder
      ::Declarative::Schema::DSL::NestedBuilder
    end
  end
end
