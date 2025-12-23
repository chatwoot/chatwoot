module Vips
  # How pixels are coded.
  #
  # Normally, pixels are uncoded and can be manipulated as you would expect.
  # However some file formats code pixels for compression, and sometimes it's
  # useful to be able to manipulate images in the coded format.
  #
  # * `:none` pixels are not coded
  # * `:labq` pixels encode 3 float CIELAB values as 4 uchar
  # * `:rad` pixels encode 3 float RGB as 4 uchar (Radiance coding)
  class Coding < Symbol
  end
end
