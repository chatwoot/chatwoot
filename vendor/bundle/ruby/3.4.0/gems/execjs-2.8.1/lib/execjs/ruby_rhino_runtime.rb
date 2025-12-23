require "execjs/runtime"

module ExecJS
  class RubyRhinoRuntime < Runtime
    class Context < Runtime::Context
      def initialize(runtime, source = "", options = {})
        source = encode(source)

        @rhino_context = ::Rhino::Context.new
        fix_memory_limit! @rhino_context
        @rhino_context.eval(source)
      rescue Exception => e
        raise wrap_error(e)
      end

      def exec(source, options = {})
        source = encode(source)

        if /\S/ =~ source
          eval "(function(){#{source}})()", options
        end
      end

      def eval(source, options = {})
        source = encode(source)

        if /\S/ =~ source
          unbox @rhino_context.eval("(#{source})")
        end
      rescue Exception => e
        raise wrap_error(e)
      end

      def call(properties, *args)
        unbox @rhino_context.eval(properties).call(*args)
      rescue Exception => e
        raise wrap_error(e)
      end

      def unbox(value)
        case value = ::Rhino::to_ruby(value)
        when Java::OrgMozillaJavascript::NativeFunction
          nil
        when Java::OrgMozillaJavascript::NativeObject
          value.inject({}) do |vs, (k, v)|
            case v
            when Java::OrgMozillaJavascript::NativeFunction, ::Rhino::JS::Function
              nil
            else
              vs[k] = unbox(v)
            end
            vs
          end
        when Array
          value.map { |v| unbox(v) }
        else
          value
        end
      end

      def wrap_error(e)
        return e unless e.is_a?(::Rhino::JSError)

        error_class = e.message == "syntax error" ? RuntimeError : ProgramError

        stack = e.backtrace
        stack = stack.map { |line| line.sub(" at ", "").sub("<eval>", "(execjs)").strip }
        stack.unshift("(execjs):1") if e.javascript_backtrace.empty?

        error = error_class.new(e.value.to_s)
        error.set_backtrace(stack)
        error
      end

      private
        # Disables bytecode compiling which limits you to 64K scripts
        def fix_memory_limit!(context)
          if context.respond_to?(:optimization_level=)
            context.optimization_level = -1
          else
            context.instance_eval { @native.setOptimizationLevel(-1) }
          end
        end
    end

    def name
      "therubyrhino (Rhino)"
    end

    def available?
      require "rhino"
      true
    rescue LoadError
      false
    end
  end
end
