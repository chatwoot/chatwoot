#!/usr/bin/ruby

require "vips"
require "down/http"

# byte_source = File.open ARGV[0], "rb"
# eg. https://images.unsplash.com/photo-1491933382434-500287f9b54b
byte_source = Down::Http.open(ARGV[0])

source = Vips::SourceCustom.new
source.on_read do |length|
  puts "reading #{length} bytes ..."
  byte_source.read length
end
source.on_seek do |offset, whence|
  puts "seeking to #{offset}, #{whence}"
  byte_source.seek(offset, whence)
end

byte_target = File.open ARGV[1], "wb"
target = Vips::TargetCustom.new
target.on_write { |chunk| byte_target.write(chunk) }
target.on_finish { byte_target.close }

image = Vips::Image.new_from_source source, "", access: :sequential
image.write_to_target target, ".jpg"
