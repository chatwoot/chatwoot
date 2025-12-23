#!/usr/bin/ruby

require "vips"

# this makes vips keep a list of all active objects
Vips.leak_set true

# disable the operation cache
# Vips::cache_set_max 0

# turn on debug logging
# Vips.set_debug true

ARGV.each do |filename|
  im = Vips::Image.new_from_file filename
  profile = im.get_value "icc-profile-data"
  puts "profile has #{profile.length} bytes"
end
