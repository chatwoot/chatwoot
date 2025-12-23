module Vips
  # How the values in an image should be interpreted. For example, a
  # three-band float image of type :lab should have its
  # pixels interpreted as coordinates in CIE Lab space.
  #
  # * `:multiband` generic many-band image
  # * `:b_w` some kind of single-band image
  # * `:histogram` a 1D image, eg. histogram or lookup table
  # * `:fourier` image is in fourier space
  # * `:xyz` the first three bands are CIE XYZ
  # * `:lab` pixels are in CIE Lab space
  # * `:cmyk` the first four bands are in CMYK space
  # * `:labq` implies #VIPS_CODING_LABQ
  # * `:rgb` generic RGB space
  # * `:cmc` a uniform colourspace based on CMC(1:1)
  # * `:lch` pixels are in CIE LCh space
  # * `:labs` CIE LAB coded as three signed 16-bit values
  # * `:srgb` pixels are sRGB
  # * `:hsv` pixels are HSV
  # * `:scrgb` pixels are scRGB
  # * `:yxy` pixels are CIE Yxy
  # * `:rgb16` generic 16-bit RGB
  # * `:grey16` generic 16-bit mono
  # * `:matrix` a matrix
  class Interpretation < Symbol
  end
end
