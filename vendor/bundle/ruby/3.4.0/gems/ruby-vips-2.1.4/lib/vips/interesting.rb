module Vips
  # Pick the algorithm vips uses to decide image "interestingness". This is
  # used by {Image#smartcrop}, for example, to decide what parts of the image
  # to keep.
  #
  # * `:none` do nothing
  # * `:centre` just take the centre
  # * `:entropy` use an entropy measure
  # * `:attention` look for features likely to draw human attention

  class Interesting < Symbol
  end
end
