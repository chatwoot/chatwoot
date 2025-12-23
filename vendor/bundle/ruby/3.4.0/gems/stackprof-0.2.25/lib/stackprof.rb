if RUBY_ENGINE == 'truffleruby'
  require "stackprof/truffleruby"
else
  require "stackprof/stackprof"
end

if defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
  StackProf.use_postponed_job!
elsif RUBY_VERSION == "3.2.0"
  # 3.2.0 crash is the signal is received at the wrong time.
  # Fixed in https://github.com/ruby/ruby/pull/7116
  # The fix is backported in 3.2.1: https://bugs.ruby-lang.org/issues/19336
  StackProf.use_postponed_job!
end

module StackProf
  VERSION = '0.2.25'
end

StackProf.autoload :Report, "stackprof/report.rb"
StackProf.autoload :Middleware, "stackprof/middleware.rb"
