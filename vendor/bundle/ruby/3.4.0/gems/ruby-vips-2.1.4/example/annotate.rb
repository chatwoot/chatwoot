#!/usr/bin/ruby

require "vips"

im = Vips::Image.new_from_file ARGV[0], access: :sequential

left_text = Vips::Image.text "left corner", dpi: 300
left = left_text.embed 50, 50, im.width, 150

right_text = Vips::Image.text "right corner", dpi: 300
right = right_text.embed im.width - right_text.width - 50, 50, im.width, 150

footer = (left | right).ifthenelse(0, [255, 0, 0], blend: true)

im = im.insert footer, 0, im.height, expand: true

im.write_to_file ARGV[1]
