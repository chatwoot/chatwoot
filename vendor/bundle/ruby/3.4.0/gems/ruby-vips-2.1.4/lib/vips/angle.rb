module Vips
  # Various fixed 90 degree rotation angles. See {Image#rot}.
  #
  # * `:d0` no rotate
  # * `:d90` 90 degrees clockwise
  # * `:d180` 180 degrees
  # * `:d270` 90 degrees anti-clockwise

  class Angle < Symbol
  end
end
