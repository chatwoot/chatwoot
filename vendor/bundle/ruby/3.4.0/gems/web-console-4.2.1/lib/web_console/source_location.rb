# frozen_string_literal: true

module WebConsole
  class SourceLocation
    def initialize(binding)
      @binding = binding
    end

    if RUBY_VERSION >= "2.6"
      def path() @binding.source_location.first end
      def lineno() @binding.source_location.last end
    else
      def path() @binding.eval("__FILE__") end
      def lineno() @binding.eval("__LINE__") end
    end
  end
end
