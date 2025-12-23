#!/usr/bin/ruby

require "vips"

# this makes vips keep a list of all active objects
# Vips::leak_set true

# disable the operation cache
# Vips::cache_set_max 0

# turn on debug logging
# Vips.set_debug true

if ARGV.length < 2
  raise "usage: #{$PROGRAM_NAME}: input-file output-file"
end

im = Vips::Image.new_from_file ARGV[0], access: :sequential

im *= [1, 2, 1]

# we want to be able to specify a scale for the convolution mask, so we have to
# make it ourselves
# if you are OK with scale=1, you can just pass the array directly to .conv()
mask = Vips::Image.new_from_array [[-1, -1, -1],
  [-1, 16, -1],
  [-1, -1, -1]], 8
im = im.conv mask

im.write_to_file ARGV[1]
