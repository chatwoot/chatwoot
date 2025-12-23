#!/usr/bin/env ruby
exec(File.expand_path("../../vendor/FlameGraph/flamegraph.pl", __FILE__), *ARGV)
