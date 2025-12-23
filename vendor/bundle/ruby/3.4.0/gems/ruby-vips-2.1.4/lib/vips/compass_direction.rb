module Vips
  # A direction on a compass used for placing images. See {Image#gravity}.
  #
  # * `:centre`
  # * `:north`
  # * `:east`
  # * `:south`
  # * `:west`
  # * `:"north-east"`
  # * `:"south-east"`
  # * `:"south-west"`
  # * `:"north-west"`

  class CompassDirection < Symbol
  end
end
