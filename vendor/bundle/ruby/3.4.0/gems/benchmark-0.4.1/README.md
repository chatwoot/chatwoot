# Benchmark

The Benchmark module provides methods for benchmarking Ruby code, giving detailed reports on the time taken for each task.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'benchmark'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install benchmark

## Usage

The Benchmark module provides methods to measure and report the time used to execute Ruby code.

Measure the time to construct the string given by the expression <code>"a"*1_000_000_000</code>:

```ruby
require 'benchmark'
puts Benchmark.measure { "a"*1_000_000_000 }
```

On my machine (OSX 10.8.3 on i5 1.7 GHz) this generates:

```
0.350000   0.400000   0.750000 (  0.835234)
```

This report shows the user CPU time, system CPU time, the total time (sum of user CPU time, system CPU time, children's user CPU time, and children's system CPU time), and the elapsed real time. The unit of time is seconds.

Do some experiments sequentially using the #bm method:

```ruby
require 'benchmark'
n = 5000000
Benchmark.bm do |x|
  x.report { for i in 1..n; a = "1"; end }
  x.report { n.times do   ; a = "1"; end }
  x.report { 1.upto(n) do ; a = "1"; end }
end
```

The result:

```
    user     system      total        real
1.010000   0.000000   1.010000 (  1.014479)
1.000000   0.000000   1.000000 (  0.998261)
0.980000   0.000000   0.980000 (  0.981335)
```

Continuing the previous example, put a label in each report:

```ruby
require 'benchmark'
n = 5000000
Benchmark.bm(7) do |x|
  x.report("for:")   { for i in 1..n; a = "1"; end }
  x.report("times:") { n.times do   ; a = "1"; end }
  x.report("upto:")  { 1.upto(n) do ; a = "1"; end }
end
```

The result:

```
              user     system      total        real
for:      1.010000   0.000000   1.010000 (  1.015688)
times:    1.000000   0.000000   1.000000 (  1.003611)
upto:     1.030000   0.000000   1.030000 (  1.028098)
```

The times for some benchmarks depend on the order in which items are run.  These differences are due to the cost of memory allocation and garbage collection. To avoid these discrepancies, the #bmbm method is provided.  For example, to compare ways to sort an array of floats:

```ruby
require 'benchmark'
array = (1..1000000).map { rand }
Benchmark.bmbm do |x|
  x.report("sort!") { array.dup.sort! }
  x.report("sort")  { array.dup.sort  }
end
```

The result:

```
Rehearsal -----------------------------------------
sort!   1.490000   0.010000   1.500000 (  1.490520)
sort    1.460000   0.000000   1.460000 (  1.463025)
-------------------------------- total: 2.960000sec
            user     system      total        real
sort!   1.460000   0.000000   1.460000 (  1.460465)
sort    1.450000   0.010000   1.460000 (  1.448327)
```

Report statistics of sequential experiments with unique labels, using the #benchmark method:

```ruby
require 'benchmark'
include Benchmark         # we need the CAPTION and FORMAT constants
n = 5000000
Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |x|
  tf = x.report("for:")   { for i in 1..n; a = "1"; end }
  tt = x.report("times:") { n.times do   ; a = "1"; end }
  tu = x.report("upto:")  { 1.upto(n) do ; a = "1"; end }
  [tf+tt+tu, (tf+tt+tu)/3]
end
```

The result:

```
             user     system      total        real
for:      0.950000   0.000000   0.950000 (  0.952039)
times:    0.980000   0.000000   0.980000 (  0.984938)
upto:     0.950000   0.000000   0.950000 (  0.946787)
>total:   2.880000   0.000000   2.880000 (  2.883764)
>avg:     0.960000   0.000000   0.960000 (  0.961255)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/benchmark.
