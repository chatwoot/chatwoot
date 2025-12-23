module Vips
  # Operations like {Image#flip} need to be told whether to flip
  # left-right or top-bottom.
  #
  # *   `:horizontal` left-right
  # *   `:vertical` top-bottom

  class Direction < Symbol
  end
end
