require "execjs/encoding"

module ExecJS
  # Abstract base class for runtimes
  class Runtime
    class Context
      include Encoding

      def initialize(runtime, source = "", options = {})
      end

      # Evaluates the +source+ in the context of a function body and returns the
      # returned value.
      #
      #   context.exec("return 1") # => 1
      #   context.exec("1")        # => nil (nothing was returned)
      def exec(source, options = {})
        raise NotImplementedError
      end

      # Evaluates the +source+ as an expression and returns the result.
      #
      #   context.eval("1")        # => 1
      #   context.eval("return 1") # => Raises SyntaxError
      def eval(source, options = {})
        raise NotImplementedError
      end

      # Evaluates +source+ as an expression (which should be of type
      # +function+), and calls the function with the given arguments.
      # The function will be evaluated with the global object as +this+.
      #
      #   context.call("function(a, b) { return a + b }", 1, 1) # => 2
      #   context.call("CoffeeScript.compile", "1 + 1")
      def call(source, *args)
        raise NotImplementedError
      end
    end

    def name
      raise NotImplementedError
    end

    def context_class
      self.class::Context
    end

    def exec(source, options = {})
      context = compile("", options)

      if context.method(:exec).arity == 1
        context.exec(source)
      else
        context.exec(source, options)
      end
    end

    def eval(source, options = {})
      context = compile("", options)

      if context.method(:eval).arity == 1
        context.eval(source)
      else
        context.eval(source, options)
      end
    end

    def compile(source, options = {})
      if context_class.instance_method(:initialize).arity == 2
        context_class.new(self, source)
      else
        context_class.new(self, source, options)
      end
    end

    def deprecated?
      false
    end

    def available?
      raise NotImplementedError
    end
  end
end
