module Vips
  # The math operation to perform on an image. See {Image#math}.
  #
  # * ':sin' sin(), angles in degrees
  # * ':cos' cos(), angles in degrees
  # * ':tan' tan(), angles in degrees
  # * ':asin' asin(), angles in degrees
  # * ':acos' acos(), angles in degrees
  # * ':atan' atan(), angles in degrees
  # * ':log' log base e
  # * ':log10' log base 10
  # * ':exp' e to the something
  # * ':exp10' 10 to the something

  class OperationMath < Symbol
  end
end
