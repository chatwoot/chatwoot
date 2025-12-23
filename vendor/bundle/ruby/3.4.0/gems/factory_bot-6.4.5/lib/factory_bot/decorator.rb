module FactoryBot
  class Decorator < BasicObject
    undef_method :==

    def initialize(component)
      @component = component
    end

    def method_missing(...) # rubocop:disable Style/MethodMissingSuper
      @component.send(...)
    end

    def send(...)
      __send__(...)
    end

    def respond_to_missing?(name, include_private = false)
      @component.respond_to?(name, true) || super
    end

    def self.const_missing(name)
      ::Object.const_get(name)
    end
  end
end
