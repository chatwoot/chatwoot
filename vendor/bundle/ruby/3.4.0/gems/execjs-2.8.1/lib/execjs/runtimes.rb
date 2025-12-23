require "execjs/module"
require "execjs/disabled_runtime"
require "execjs/duktape_runtime"
require "execjs/external_runtime"
require "execjs/ruby_rhino_runtime"
require "execjs/mini_racer_runtime"

module ExecJS
  module Runtimes
    Disabled = DisabledRuntime.new

    Duktape = DuktapeRuntime.new

    RubyRhino = RubyRhinoRuntime.new

    MiniRacer = MiniRacerRuntime.new

    Node = ExternalRuntime.new(
      name:        "Node.js (V8)",
      command:     ["node", "nodejs"],
      runner_path: ExecJS.root + "/support/node_runner.js",
      encoding:    'UTF-8'
    )

    JavaScriptCore = ExternalRuntime.new(
      name:        "JavaScriptCore",
      command:     [
        "/System/Library/Frameworks/JavaScriptCore.framework/Versions/Current/Helpers/jsc",
        "/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc",
      ],
      runner_path: ExecJS.root + "/support/jsc_runner.js"
    )

    SpiderMonkey = Spidermonkey = ExternalRuntime.new(
      name:        "SpiderMonkey",
      command:     "js",
      runner_path: ExecJS.root + "/support/spidermonkey_runner.js",
      deprecated:  true
    )

    JScript = ExternalRuntime.new(
      name:        "JScript",
      command:     "cscript //E:jscript //Nologo //U",
      runner_path: ExecJS.root + "/support/jscript_runner.js",
      encoding:    'UTF-16LE' # CScript with //U returns UTF-16LE
    )

    V8 = ExternalRuntime.new(
      name:        "V8",
      command:     "d8",
      runner_path: ExecJS.root + "/support/v8_runner.js",
      encoding:    'UTF-8'
    )


    def self.autodetect
      from_environment || best_available ||
        raise(RuntimeUnavailable, "Could not find a JavaScript runtime. " +
          "See https://github.com/rails/execjs for a list of available runtimes.")
    end

    def self.best_available
      runtimes.reject(&:deprecated?).find(&:available?)
    end

    def self.from_environment
      env = ENV["EXECJS_RUNTIME"]
      if env && !env.empty?
        name = env
        raise RuntimeUnavailable, "#{name} runtime is not defined" unless const_defined?(name)
        runtime = const_get(name)

        raise RuntimeUnavailable, "#{runtime.name} runtime is not available on this system" unless runtime.available?
        runtime
      end
    end

    def self.names
      @names ||= constants.inject({}) { |h, name| h.merge(const_get(name) => name) }.values
    end

    def self.runtimes
      @runtimes ||= [
        RubyRhino,
        Duktape,
        MiniRacer,
        Node,
        JavaScriptCore,
        SpiderMonkey,
        JScript,
        V8
      ]
    end
  end

  def self.runtimes
    Runtimes.runtimes
  end
end
