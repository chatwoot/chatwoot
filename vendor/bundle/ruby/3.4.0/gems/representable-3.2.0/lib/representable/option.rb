require "trailblazer/option"

module Representable
  # Extend `Trailblazer::Option` to support static values as callables too.
  class Option < ::Trailblazer::Option
    def self.callable?(value)
      [Proc, Symbol, Uber::Callable].any?{ |kind| value.is_a?(kind) }
    end

    def self.build(value)
      return ->(*) { value } unless callable?(value) # Wrap static `value` into a proc. 
      super
    end
  end

  def self.Option(value)
    ::Representable::Option.build(value)
  end
end
