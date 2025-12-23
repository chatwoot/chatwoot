module Vips
  # Various fixed 45 degree rotation angles. See {Image#rot45}.
  #
  # * `:d0` no rotate
  # * `:d45` 45 degrees clockwise
  # * `:d90` 90 degrees clockwise
  # * `:d135` 135 degrees clockwise
  # * `:d180` 180 degrees
  # * `:d225` 135 degrees anti-clockwise
  # * `:d270` 90 degrees anti-clockwise
  # * `:d315` 45 degrees anti-clockwise

  class Angle45 < Symbol
  end
end
