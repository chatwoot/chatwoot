#!/usr/bin/env ruby

require 'mini_magick'

puts 'Testing MiniMagick animation detection'
image = MiniMagick::Image.open('app/uploaders/200.webp')
puts "Frames count: #{image.frames.count}"
puts "Image format: #{image.mime_type}"
puts "Image size: #{image.size}"

# Test manually loading the file
puts "\nTesting frame detection:"
image.frames.each_with_index do |frame, index|
  puts "Frame #{index}: #{frame.dimensions.join('x')}"
end
