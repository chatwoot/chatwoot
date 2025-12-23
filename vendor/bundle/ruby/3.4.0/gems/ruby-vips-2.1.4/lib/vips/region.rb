# This module provides an interface to the top level bits of libvips
# via ruby-ffi.
#
# Author::    John Cupitt  (mailto:jcupitt@gmail.com)
# License::   MIT

require "ffi"

module Vips
  attach_function :vips_region_new, [:pointer], :pointer

  if Vips.at_least_libvips?(8, 8)
    attach_function :vips_region_fetch, [:pointer, :int, :int, :int, :int, SizeStruct.ptr], :pointer
    attach_function :vips_region_width, [:pointer], :int
    attach_function :vips_region_height, [:pointer], :int
  end

  # A region on an image. Create one, then use `fetch` to quickly get a region
  # of pixels.
  #
  # For example:
  #
  #  ```ruby
  #  region = Vips::Region.new(image)
  #  pixels = region.fetch(10, 10, 100, 100)
  #  ```
  class Region < Vips::Object
    # The layout of the VipsRegion struct.
    module RegionLayout
      def self.included(base)
        base.class_eval do
          layout :parent, Vips::Object::Struct
          # rest opaque
        end
      end
    end

    class Struct < Vips::Object::Struct
      include RegionLayout
    end

    class ManagedStruct < Vips::Object::ManagedStruct
      include RegionLayout
    end

    def initialize(name)
      ptr = Vips.vips_region_new name
      raise Vips::Error if ptr.null?

      super ptr
    end

    def width
      Vips.vips_region_width self
    end

    def height
      Vips.vips_region_height self
    end

    # Fetch a region filled with pixel data.
    def fetch(left, top, width, height)
      len = Vips::SizeStruct.new
      ptr = Vips.vips_region_fetch self, left, top, width, height, len
      raise Vips::Error if ptr.null?

      # wrap up as an autopointer
      ptr = FFI::AutoPointer.new(ptr, GLib::G_FREE)

      ptr.get_bytes 0, len[:value]
    end
  end
end
