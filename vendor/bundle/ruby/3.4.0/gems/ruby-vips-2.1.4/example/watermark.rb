#!/usr/bin/ruby

require "vips"

im = Vips::Image.new_from_file ARGV[0], access: :sequential

# make the text mask
text = Vips::Image.text ARGV[2], width: 200, dpi: 200, font: "sans bold"
text = text.rotate(-45)
# make the text transparent
text = (text * 0.3).cast(:uchar)
text = text.gravity :centre, 200, 200
text = text.replicate 1 + im.width / text.width, 1 + im.height / text.height
text = text.crop 0, 0, im.width, im.height

# we make a constant colour image and attach the text mask as the alpha
overlay = (text.new_from_image [255, 128, 128]).copy interpretation: :srgb
overlay = overlay.bandjoin text

# overlay the text
im = im.composite overlay, :over

im.write_to_file ARGV[1]
