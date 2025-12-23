#!/usr/bin/env ruby
exec(File.expand_path("../../vendor/gprof2dot/gprof2dot.py", __FILE__), *ARGV)
