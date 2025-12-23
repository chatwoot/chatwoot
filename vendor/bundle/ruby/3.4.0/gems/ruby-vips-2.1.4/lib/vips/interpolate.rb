module Vips
  attach_function :vips_interpolate_new, [:string], :pointer

  # An interpolator. One of these can be given to operations like
  # {Image#affine} or {Image#mapim} to select the type of pixel interpolation
  # to use.
  #
  # To see all interpolators supported by your
  # libvips, try
  #
  # ```
  # $ vips -l interpolate
  # ```
  #
  # But at least these should be available:
  #
  # *   `:nearest` Nearest-neighbour interpolation.
  # *   `:bilinear` Bilinear interpolation.
  # *   `:bicubic` Bicubic interpolation.
  # *   `:lbb` Reduced halo bicubic interpolation.
  # *   `:nohalo` Edge sharpening resampler with halo reduction.
  # *   `:vsqbs` B-Splines with antialiasing smoothing.
  #
  #  For example:
  #
  #  ```ruby
  #  im = im.affine [2, 0, 0, 2],
  #      :interpolate => Vips::Interpolate.new(:bicubic)
  #  ```

  class Interpolate < Vips::Object
    # the layout of the VipsInterpolate struct
    module InterpolateLayout
      def self.included base
        base.class_eval do
          layout :parent, Vips::Object::Struct
          # rest opaque
        end
      end
    end

    class Struct < Vips::Object::Struct
      include InterpolateLayout
    end

    class ManagedStruct < Vips::Object::ManagedStruct
      include InterpolateLayout
    end

    def initialize name
      name = name.to_s if name.is_a? Symbol
      ptr = Vips.vips_interpolate_new name
      raise Vips::Error if ptr.nil?

      super ptr
    end
  end
end
