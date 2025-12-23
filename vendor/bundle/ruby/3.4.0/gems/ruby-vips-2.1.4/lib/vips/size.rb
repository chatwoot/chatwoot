module Vips
  # Controls whether an operation should upsize, downsize, or both up and
  # downsize.
  #
  # * `:both` size both up and down
  # * `:up` only upsize
  # * `:down` only downsize
  # * `:force` change aspect ratio

  class Size < Symbol
  end
end
