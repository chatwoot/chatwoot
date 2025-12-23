#!/usr/bin/ruby

# An equivalent of ImageMagick's -trim in ruby-vips ... automatically remove
# "boring" image edges.

# We use .project to sum the rows and columns of a 0/255 mask image, the first
# non-zero row or column is the object edge. We make the mask image with an
# amount-different-from-background image plus a threshold.

require "vips"

im = Vips::Image.new_from_file ARGV[0]

# find the value of the pixel at (0, 0) ... we will search for all pixels
# significantly different from this
background = im.getpoint(0, 0)

# we need to smooth the image, subtract the background from every pixel, take
# the absolute value of the difference, then threshold
mask = (im.median - background).abs > 10

# sum mask rows and columns, then search for the first non-zero sum in each
# direction
columns, rows = mask.project

_first_column, first_row = columns.profile
left = first_row.min

_first_column, first_row = columns.fliphor.profile
right = columns.width - first_row.min

first_column, _first_row = rows.profile
top = first_column.min

first_column, _first_row = rows.flipver.profile
bottom = rows.height - first_column.min

# and now crop the original image
im = im.crop left, top, right - left, bottom - top

im.write_to_file ARGV[1]
