module Vips
  # Various types of alignment. See {Image#join}, for example.
  #
  # * `:low` Align on the low coordinate edge
  # * `:centre` Align on the centre
  # * `:high` Align on the high coordinate edge

  class Align < Symbol
  end
end
