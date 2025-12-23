require "execjs/runtime"

module ExecJS
  class DisabledRuntime < Runtime
    def name
      "Disabled"
    end

    def exec(source, options = {})
      raise Error, "ExecJS disabled"
    end

    def eval(source, options = {})
      raise Error, "ExecJS disabled"
    end

    def compile(source, options = {})
      raise Error, "ExecJS disabled"
    end

    def deprecated?
      true
    end

    def available?
      true
    end
  end
end
