require "execjs/runtime"
require "json"

module ExecJS
  class DuktapeRuntime < Runtime
    class Context < Runtime::Context
      def initialize(runtime, source = "", options = {})
        @ctx = Duktape::Context.new(complex_object: nil)
        @ctx.exec_string(encode(source), '(execjs)')
      rescue Exception => e
        raise wrap_error(e)
      end

      def exec(source, options = {})
        return unless /\S/ =~ source
        @ctx.eval_string("(function(){#{encode(source)}})()", '(execjs)')
      rescue Exception => e
        raise wrap_error(e)
      end

      def eval(source, options = {})
        return unless /\S/ =~ source
        @ctx.eval_string("(#{encode(source)})", '(execjs)')
      rescue Exception => e
        raise wrap_error(e)
      end

      def call(identifier, *args)
        @ctx.exec_string("__execjs_duktape_call = #{identifier}", '(execjs)')
        @ctx.call_prop("__execjs_duktape_call", *args)
      rescue Exception => e
        raise wrap_error(e)
      end

      private
        def wrap_error(e)
          klass = case e
          when Duktape::SyntaxError
            RuntimeError
          when Duktape::Error
            ProgramError
          when Duktape::InternalError
            RuntimeError
          end

          if klass
            re = / \(line (\d+)\)$/
            lineno = e.message[re, 1] || 1
            error = klass.new(e.message.sub(re, ""))
            error.set_backtrace(["(execjs):#{lineno}"] + e.backtrace)
            error
          else
            e
          end
        end
    end

    def name
      "Duktape"
    end

    def available?
      require "duktape"
      true
    rescue LoadError
      false
    end
  end
end
