#!/usr/bin/ruby

require "logger"
require "vips"

puts ""
puts "starting up:"

# this makes vips keep a list of all active objects which we can print out
Vips.leak_set true

# disable the operation cache
Vips.cache_set_max 0

# GLib::logger.level = Logger::DEBUG

n = 10000

n.times do |i|
  puts ""
  puts "call #{i} ..."
  out = Vips::Operation.call "black", [200, 300]
  if out.width != 200 || out.height != 300
    puts "bad image result from black"
  end
end

puts ""
puts "after #{n} calls:"
GC.start
Vips::Object.print_all

puts ""
puts "shutting down:"
