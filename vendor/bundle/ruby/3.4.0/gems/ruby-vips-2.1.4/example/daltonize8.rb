#!/usr/bin/ruby

# daltonize an image with ruby-vips
# based on
# http://scien.stanford.edu/pages/labsite/2005/psych221/projects/05/ofidaner/colorblindness_project.htm
# see
# http://libvips.blogspot.co.uk/2013/05/daltonize-in-ruby-vips-carrierwave-and.html
# for a discussion of this code

require "vips"

# Vips.set_debug true

# matrices to convert D65 XYZ to and from bradford cone space
xyz_to_brad = [
  [0.8951, 0.2664, -0.1614],
  [-0.7502, 1.7135, 0.0367],
  [0.0389, -0.0685, 1.0296]
]
brad_to_xyz = [
  [0.987, -0.147, 0.16],
  [0.432, 0.5184, 0.0493],
  [-0.0085, 0.04, 0.968]
]

im = Vips::Image.new_from_file ARGV[0]

# remove any alpha channel before processing
alpha = nil
if im.bands == 4
  alpha = im[3]
  im = im.extract_band 0, n: 3
end

begin
  # import to XYZ with lcms
  # if there's no profile there, we'll fall back to the thing below
  xyz = im.icc_import embedded: true, pcs: :xyz
rescue Vips::Error
  # nope .. use the built-in converter instead
  xyz = im.colourspace :xyz
end

brad = xyz.recomb xyz_to_brad

# through the Deuteranope matrix
# we need rows to sum to 1 in Bradford space --- the matrix in the original
# Python code sums to 1.742
deut = brad.recomb [
  [1, 0, 0],
  [0.7, 0, 0.3],
  [0, 0, 1]
]

xyz = deut.recomb brad_to_xyz

# .. and back to sRGB
rgb = xyz.colourspace :srgb

# so this is the colour error
err = im - rgb

# add the error back to other channels to make a compensated image
im += err.recomb([[0, 0, 0],
  [0.7, 1, 0],
  [0.7, 0, 1]])

# reattach any alpha we saved above
if alpha
  im = im.bandjoin(alpha)
end

im.write_to_file ARGV[1]
