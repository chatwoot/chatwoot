#!/usr/bin/ruby

require "vips"

image = Vips::Image.new_from_file ARGV[0]

module Vips
  class Image
    def wobble
      # this makes an image where pixel (0, 0) (at the top-left) has
      # value [0, 0], and pixel (image.width - 1, image.height - 1) at the
      # bottom-right has value [image.width - 1, image.height - 1]
      index = Vips::Image.xyz width, height

      # make a version with (0, 0) at the centre, negative values up
      # and left, positive down and right
      centre = index - [width / 2, height / 2]

      # to polar space, so each pixel is now distance and angle in degrees
      polar = centre.polar

      # scale sin(distance) by 1/distance to make a wavey pattern
      d = ((polar[0] * 3).sin * 10000) / (polar[0] + 1)

      # and back to rectangular coordinates again to make a set of
      # vectors we can apply to the original index image
      index += d.bandjoin(polar[1]).rect

      # finally, use our modified index image to distort!
      mapim index
    end
  end
end

image = image.wobble
image.write_to_file ARGV[1]
