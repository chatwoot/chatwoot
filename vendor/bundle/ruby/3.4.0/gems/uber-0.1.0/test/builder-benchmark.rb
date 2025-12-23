require "test_helper"
require "uber/options"
require "uber/option"
require "benchmark/ips"

proc = ->(options) { "great" }

value  = Uber::Options::Value.new(proc)
option = Uber::Option[proc, instance_exec: true]

Benchmark.ips do |x|
  x.report(:value)  { value.(self, {}) }
  x.report(:option) { option.(self, {}) }
end

#  value    946.110k (± 2.4%) i/s -      4.766M in   5.040395s
# option      1.583M (± 1.6%) i/s -      7.928M in   5.009953s
