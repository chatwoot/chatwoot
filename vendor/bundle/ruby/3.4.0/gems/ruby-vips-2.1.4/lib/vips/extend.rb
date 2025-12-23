module Vips
  # When the edges of an image are extended, you can specify
  # how you want the extension done.
  # See {Image#embed}, {Image#conv}, {Image#affine} and
  # so on.
  #
  # * `:black` new pixels are black, ie. all bits are zero.
  # * `:copy` each new pixel takes the value of the nearest edge pixel
  # * `:repeat` the image is tiled to fill the new area
  # * `:mirror` the image is reflected and tiled to reduce hash edges
  # * `:white` new pixels are white, ie. all bits are set
  # * `:background` colour set from the @background property

  class Extend < Symbol
  end
end
