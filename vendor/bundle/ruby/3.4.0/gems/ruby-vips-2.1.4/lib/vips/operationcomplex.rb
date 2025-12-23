module Vips
  # The type of complex operation to perform on an image. See
  # {Image#complex}.
  #
  # * ':polar' to polar coordinates
  # * ':rect' to rectangular coordinates
  # * ':conj' complex conjugate

  class OperationComplex < Symbol
  end
end
