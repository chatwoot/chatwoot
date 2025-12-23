module Vips
  # Blend mode to use when compositing images. See {Image#composite}.
  #
  # * `:clear` where the second object is drawn, the first is removed
  # * `:source` the second object is drawn as if nothing were below
  # * `:over` the image shows what you would expect if you held two
  #    semi-transparent slides on top of each other
  # * `:in` the first object is removed completely, the second is only
  #    drawn where the first was
  # * `:out` the second is drawn only where the first isn't
  # * `:atop` this leaves the first object mostly intact, but mixes both
  #    objects in the overlapping area
  # * `:dest` leaves the first object untouched, the second is discarded
  #    completely
  # * `:dest_over` like `:over`, but swaps the arguments
  # * `:dest_in` like `:in`, but swaps the arguments
  # * `:dest_out` like `:out`, but swaps the arguments
  # * `:dest_atop` like `:atop`, but swaps the arguments
  # * `:xor` something like a difference operator
  # * `:add` a bit like adding the two images
  # * `:saturate` a bit like the darker of the two
  # * `:multiply` at least as dark as the darker of the two inputs
  # * `:screen` at least as light as the lighter of the inputs
  # * `:overlay` multiplies or screens colors, depending on the lightness
  # * `:darken` the darker of each component
  # * `:lighten` the lighter of each component
  # * `:colour_dodge` brighten first by a factor second
  # * `:colour_burn` darken first by a factor of second
  # * `:hard_light` multiply or screen, depending on lightness
  # * `:soft_light` darken or lighten, depending on lightness
  # * `:difference` difference of the two
  # * `:exclusion` somewhat like `:difference`, but lower-contrast

  class BlendMode < Symbol
  end
end
