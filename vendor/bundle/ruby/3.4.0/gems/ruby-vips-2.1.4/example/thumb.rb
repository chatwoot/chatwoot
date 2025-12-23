#!/usr/bin/ruby

# batch-process a lot of files
#
# this should run in constant memory -- if it doesn't, something has broken

require "vips"

# benchmark thumbnail via a memory buffer
def via_memory(filename, thumbnail_width)
  data = IO.binread(filename)

  thumb = Vips::Image.thumbnail_buffer data, thumbnail_width, crop: "centre"

  thumb.write_to_buffer ".jpg"
end

# benchmark thumbnail via files
def via_files(filename, thumbnail_width)
  thumb = Vips::Image.thumbnail filename, thumbnail_width, crop: "centre"

  thumb.write_to_buffer ".jpg"
end

ARGV.each do |filename|
  puts "processing #{filename} ..."
  _thumb = via_memory(filename, 500)
  # _thumb = via_files(filename, 500)
end
