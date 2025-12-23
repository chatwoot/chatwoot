require "execjs/module"
require "execjs/runtimes"

module ExecJS
  self.runtime ||= Runtimes.autodetect
end
