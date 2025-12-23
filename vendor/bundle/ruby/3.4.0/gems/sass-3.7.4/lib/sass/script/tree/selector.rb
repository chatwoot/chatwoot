module Sass::Script::Tree
  # A SassScript node that will resolve to the current selector.
  class Selector < Node
    def initialize; end

    def children
      []
    end

    def to_sass(opts = {})
      '&'
    end

    def deep_copy
      dup
    end

    protected

    def _perform(environment)
      selector = environment.selector
      return opts(Sass::Script::Value::Null.new) unless selector
      opts(selector.to_sass_script)
    end
  end
end
