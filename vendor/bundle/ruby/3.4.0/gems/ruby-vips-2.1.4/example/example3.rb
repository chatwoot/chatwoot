#!/usr/bin/ruby

require "vips"

# this makes vips keep a list of all active objects
Vips.leak_set true

# disable the operation cache
# Vips::cache_set_max 0

# turn on debug logging
GLib.logger.level = Logger::DEBUG

10.times do |i|
  puts "loop #{i} ..."
  im = Vips::Image.new_from_file ARGV[0]
  im = im.embed 100, 100, 3000, 3000, extend: :mirror
  im.write_to_file "x.v"
end
