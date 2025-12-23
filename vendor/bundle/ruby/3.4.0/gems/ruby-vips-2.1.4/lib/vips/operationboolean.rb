module Vips
  # The type of boolean operation to perform on an image. See
  # {Image#boolean}.
  #
  # * ':and' bitwise and
  # * ':or' bitwise or
  # * ':eor' bitwise eor
  # * ':lshift' shift left n bits
  # * ':rshift' shift right n bits

  class OperationBoolean < Symbol
  end
end
