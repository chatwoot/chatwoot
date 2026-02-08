#!/usr/bin/env ruby

require 'mini_magick'

puts 'Testing MiniMagick.dup with animated WebP'
image = MiniMagick::Image.open('app/uploaders/200.webp')
puts "Original frames count: #{image.frames.count}"

duplicated = image.dup
puts "Duplicated frames count: #{duplicated.frames.count}"

# Test coalesce
coalesced = image.coalesce
puts "Coalesced frames count: #{coalesced.frames.count}"
