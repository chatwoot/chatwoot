require "test_helper"
require "uber/option"

class OptionTest < Minitest::Spec
  Option = Uber::Option

  # proc
  it { Option[ ->(*args) { "proc! #{args.inspect}" } ].(1,2).must_equal "proc! [1, 2]" }
  it { Option[ lambda { "proc!" } ].().must_equal "proc!" }

  # proc with instance_exec
  it { Option[ ->(*args) { "#{self.class} #{args.inspect}" } ].(Object, 1, 2).must_equal "OptionTest [Object, 1, 2]" }
  it { Option[ ->(*args) { "#{self} #{args.inspect}" }, instance_exec: true ].(Object, 1, 2).must_equal "Object [1, 2]" }

  # static
  it { Option[true].().must_equal true }
  it { Option[nil].().must_equal nil }
  it { Option[false].().must_equal false }
  # args are ignored.
  it { Option[true].(1,2,3).must_equal true }

  # instance method
  class Hello
    def hello(*args); "Hello! #{args.inspect}" end
  end
  it { Option[:hello].(Hello.new).must_equal "Hello! []" }
  it { Option[:hello].(Hello.new, 1, 2).must_equal "Hello! [1, 2]" }

  #---
  # Callable
  class Callio
    include Uber::Callable
    def call(); "callable!" end
  end

  it { Option[Callio.new].().must_equal "callable!" }
end

# require "benchmark/ips"

# method = Uber::Option[->(context, options) { context }]
# proc = Uber::Option[A.new { |context, options| context }]

# Benchmark.ips do |x|
#   x.report(:method) { method.(Object, {}) }
#   x.report(:proc)   { proc.(Object, {}) }
# end
