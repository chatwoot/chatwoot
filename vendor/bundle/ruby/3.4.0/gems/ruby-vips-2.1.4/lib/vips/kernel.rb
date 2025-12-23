module Vips
  # A resizing kernel. One of these can be given to operations like
  # {Image#reduceh} or {Image#resize} to select the resizing kernel to use.
  #
  # At least these should be available:
  #
  # *   `:nearest` Nearest-neighbour interpolation.
  # *   `:linear` Linear interpolation.
  # *   `:cubic` Cubic interpolation.
  # *   `:lanczos2` Two-lobe Lanczos
  # *   `:lanczos3` Three-lobe Lanczos
  #
  #  For example:
  #
  #  ```ruby
  #  im = im.resize 3, :kernel => :lanczos2
  #  ```

  class Kernel < Symbol
  end
end
