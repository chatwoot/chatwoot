require "execjs/runtime"

module ExecJS
  class MiniRacerRuntime < Runtime
    class Context < Runtime::Context
      def initialize(runtime, source = "", options={})
        source = encode(source)
        @context = ::MiniRacer::Context.new
        @context.eval("delete this.console");
        translate do
          @context.eval(source)
        end
      end

      def exec(source, options = {})
        source = encode(source)

        if /\S/ =~ source
          eval "(function(){#{source}})()"
        end
      end

      def eval(source, options = {})
        source = encode(source)

        if /\S/ =~ source
          translate do
            @context.eval("(#{source})")
          end
        end
      end

      def call(identifier, *args)
        # TODO optimise generate
        eval "#{identifier}.apply(this, #{::JSON.generate(args)})"
      end

      private

      def strip_functions!(value)
        if Array === value
          value.map! do |v|
            if MiniRacer::JavaScriptFunction === value
              nil
            else
              strip_functions!(v)
            end
          end
        elsif Hash === value
          value.each do |k,v|
            if MiniRacer::JavaScriptFunction === v
              value.delete k
            else
              value[k] = strip_functions!(v)
            end
          end
          value
        elsif MiniRacer::JavaScriptFunction === value
          nil
        else
          value
        end
      end

      def translate
        begin
          strip_functions! yield
        rescue MiniRacer::RuntimeError => e
          ex = ProgramError.new e.message
          if backtrace = e.backtrace
            backtrace = backtrace.map { |line|
              if line =~ /JavaScript at/
                line.sub("JavaScript at ", "")
                    .sub("<anonymous>", "(execjs)")
                    .strip
              else
                line
              end
            }
            ex.set_backtrace backtrace
          end
          raise ex
        rescue MiniRacer::ParseError => e
          ex = RuntimeError.new e.message
          ex.set_backtrace(["(execjs):1"] + e.backtrace)
          raise ex
        end
      end

    end

    def name
      "mini_racer (V8)"
    end

    def available?
      require "mini_racer"
      true
    rescue LoadError
      false
    end
  end
end
