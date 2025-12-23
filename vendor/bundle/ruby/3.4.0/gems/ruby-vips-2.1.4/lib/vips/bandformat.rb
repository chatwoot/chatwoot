module Vips
  # The format used for each band element. Each corresponds to a native C type
  # for the current machine.
  #
  # * `:notset` invalid setting
  # * `:uchar` unsigned char format
  # * `:char` char format
  # * `:ushort` unsigned short format
  # * `:short` short format
  # * `:uint` unsigned int format
  # * `:int` int format
  # * `:float` float format
  # * `:complex` complex (two floats) format
  # * `:double` double float format
  # * `:dpcomplex` double complex (two double) format
  class BandFormat < Symbol
  end
end
