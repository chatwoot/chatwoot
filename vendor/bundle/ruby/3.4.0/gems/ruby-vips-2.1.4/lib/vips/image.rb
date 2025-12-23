# This module provides an interface to the vips image processing library
# via ruby-ffi.
#
# Author::    John Cupitt  (mailto:jcupitt@gmail.com)
# License::   MIT

require "ffi"

module Vips
  private

  attach_function :vips_image_new_matrix_from_array,
    [:int, :int, :pointer, :int], :pointer

  attach_function :vips_image_copy_memory, [:pointer], :pointer

  attach_function :vips_image_set_progress, [:pointer, :bool], :void
  attach_function :vips_image_set_kill, [:pointer, :bool], :void

  attach_function :vips_filename_get_filename, [:string], :pointer
  attach_function :vips_filename_get_options, [:string], :pointer

  attach_function :vips_foreign_find_load, [:string], :string
  attach_function :vips_foreign_find_save, [:string], :string
  attach_function :vips_foreign_find_load_buffer, [:pointer, :size_t], :string
  attach_function :vips_foreign_find_save_buffer, [:string], :string

  if Vips.at_least_libvips?(8, 9)
    attach_function :vips_foreign_find_load_source, [:pointer], :string
    attach_function :vips_foreign_find_save_target, [:string], :string
  end

  attach_function :vips_image_write_to_memory,
    [:pointer, SizeStruct.ptr], :pointer

  attach_function :vips_image_get_typeof, [:pointer, :string], :GType
  attach_function :vips_image_get,
    [:pointer, :string, GObject::GValue.ptr], :int

  attach_function :vips_image_get_width, [:pointer], :int
  attach_function :vips_image_get_height, [:pointer], :int
  attach_function :vips_image_get_bands, [:pointer], :int

  if Vips.at_least_libvips?(8, 5)
    attach_function :vips_image_get_fields, [:pointer], :pointer
    attach_function :vips_image_hasalpha, [:pointer], :int
  end

  if Vips.at_least_libvips?(8, 6)
    attach_function :vips_addalpha, [:pointer, :pointer, :varargs], :int
  end

  # move these three lines to mutableimage when we finally remove set and
  # remove in this class
  attach_function :vips_image_set,
    [:pointer, :string, GObject::GValue.ptr], :void
  attach_function :vips_image_remove, [:pointer, :string], :void

  attach_function :vips_band_format_iscomplex, [:int], :int
  attach_function :vips_band_format_isfloat, [:int], :int

  attach_function :nickname_find, :vips_nickname_find, [:GType], :string

  attach_function :vips_image_new_from_memory, [:pointer, :size_t, :int, :int, :int, :int], :pointer
  attach_function :vips_image_new_from_memory_copy, [:pointer, :size_t, :int, :int, :int, :int], :pointer

  # turn a raw pointer that must be freed into a self-freeing Ruby string
  def self.p2str(pointer)
    pointer = FFI::AutoPointer.new(pointer, GLib::G_FREE)
    pointer.read_string
  end

  public

  # This class represents a libvips image. See the {Vips} module documentation
  # for an introduction to using this class.

  class Image < Vips::Object
    alias_method :parent_get_typeof, :get_typeof

    # FFI sets a pointer's size to this magic value if the size of the memory
    # chunk the pointer points to is unknown to FFI.
    UNKNOWN_POINTER_SIZE = FFI::Pointer.new(1).size
    private_constant :UNKNOWN_POINTER_SIZE

    private

    # the layout of the VipsImage struct
    module ImageLayout
      def self.included base
        base.class_eval do
          layout :parent, Vips::Object::Struct
          # rest opaque
        end
      end
    end

    class Struct < Vips::Object::Struct
      include ImageLayout
    end

    class ManagedStruct < Vips::Object::ManagedStruct
      include ImageLayout
    end

    class GenericPtr < FFI::Struct
      layout :value, :pointer
    end

    # handy for overloads ... want to be able to apply a function to an
    # array or to a scalar
    def self.smap x, &block
      x.is_a?(Array) ? x.map { |y| smap(y, &block) } : block.call(x)
    end

    def self.complex? format
      format_number = GObject::GValue.from_nick BAND_FORMAT_TYPE, format
      Vips.vips_band_format_iscomplex(format_number) != 0
    end

    def self.float? format
      format_number = GObject::GValue.from_nick BAND_FORMAT_TYPE, format
      Vips.vips_band_format_isfloat(format_number) != 0
    end

    # run a complex operation on a complex image, or an image with an even
    # number of bands ... handy for things like running .polar on .index
    # images
    def self.run_cmplx image, &block
      original_format = image.format

      unless Image.complex? image.format
        if image.bands % 2 != 0
          raise Vips::Error, "not an even number of bands"
        end

        unless Image.float? image.format
          image = image.cast :float
        end

        new_format = image.format == :double ? :dpcomplex : :complex
        image = image.copy format: new_format, bands: image.bands / 2
      end

      image = block.call(image)

      unless Image.complex? original_format
        new_format = image.format == :dpcomplex ? :double : :float
        image = image.copy format: new_format, bands: image.bands * 2
      end

      image
    end

    # handy for expanding enum operations
    def call_enum(name, other, enum)
      if other.is_a?(Vips::Image)
        Vips::Operation.call name.to_s, [self, other, enum]
      else
        Vips::Operation.call name.to_s + "_const", [self, enum, other]
      end
    end

    # Write can fail due to no file descriptors and memory can fill if
    # large objects are not collected fairly soon. We can't try a
    # write and GC and retry on fail, since the write may take a
    # long time and may not be repeatable.
    #
    # GCing before every write would have a horrible effect on
    # performance, so as a compromise we GC every @@gc_interval writes.
    #
    # ruby2.1 introduced a generational GC which is fast enough to be
    # able to GC on every write.

    @@generational_gc = RUBY_ENGINE == "ruby" && RUBY_VERSION.to_f >= 2.1

    @@gc_interval = 100
    @@gc_countdown = @@gc_interval

    def write_gc
      if @@generational_gc
        GC.start full_mark: false
      else
        @@gc_countdown -= 1
        if @@gc_countdown < 0
          @@gc_countdown = @@gc_interval
          GC.start
        end
      end
    end

    public

    def inspect
      "#<Image #{width}x#{height} #{format}, #{bands} bands, #{interpretation}>"
    end

    def respond_to? name, include_all = false
      # To support keyword args, we need to tell Ruby that final image
      # arguments cannot be hashes of keywords.
      #
      # https://makandracards.com/makandra/
      #   36013-heads-up-ruby-implicitly-converts-a-hash-to-keyword-arguments
      return false if name == :to_hash

      super
    end

    def respond_to_missing? name, include_all = false
      # respond to all vips operations by nickname
      return true if Vips.type_find("VipsOperation", name.to_s) != 0

      super
    end

    def self.respond_to_missing? name, include_all = false
      # respond to all vips operations by nickname
      return true if Vips.type_find("VipsOperation", name.to_s) != 0

      super
    end

    # Invoke a vips operation with {Vips::Operation.call}, using self as
    # the first input argument.
    #
    # @param name [String] vips operation to call
    # @return result of vips operation
    def method_missing name, *args, **options
      Vips::Operation.call name.to_s, [self, *args], options
    end

    # Invoke a vips operation with {Vips::Operation.call}.
    def self.method_missing name, *args, **options
      Vips::Operation.call name.to_s, args, options
    end

    # Return a new {Image} for a file on disc. This method can load
    # images in any format supported by vips. The filename can include
    # load options, for example:
    #
    # ```
    # image = Vips::Image.new_from_file "fred.jpg[shrink=2]"
    # ```
    #
    # You can also supply options as a hash, for example:
    #
    # ```
    # image = Vips::Image.new_from_file "fred.jpg", shrink: 2
    # ```
    #
    # The full set of options available depend upon the load operation that
    # will be executed. Try something like:
    #
    # ```
    # $ vips jpegload
    # ```
    #
    # at the command-line to see a summary of the available options for the
    # JPEG loader.
    #
    # Loading is fast: only enough of the image is loaded to be able to fill
    # out the header. Pixels will only be decompressed when they are needed.
    #
    # @!macro [new] vips.loadopts
    #   @param opts [Hash] set of options
    #   @option opts [Boolean] :disc (true) Open large images via a
    #     temporary disc file
    #   @option opts [Vips::Access] :access (:random) Access mode for file
    #
    # @param name [String] the filename to load from
    # @macro vips.loadopts
    # @return [Image] the loaded image
    def self.new_from_file name, **opts
      # very common, and Vips::vips_filename_get_filename will segv if we
      # pass this
      raise Vips::Error, "filename is nil" if name.nil?

      filename = Vips.p2str(Vips.vips_filename_get_filename(name))
      option_string = Vips.p2str(Vips.vips_filename_get_options(name))
      loader = Vips.vips_foreign_find_load filename
      raise Vips::Error if loader.nil?

      Operation.call loader, [filename], opts, option_string
    end

    # Create a new {Image} for an image encoded in a format such as
    # JPEG in a binary string. Load options may be passed as
    # strings or appended as a hash. For example:
    #
    # ```
    # image = Vips::Image.new_from_buffer memory_buffer, "shrink=2"
    # ```
    #
    # or alternatively:
    #
    # ```
    # image = Vips::Image.new_from_buffer memory_buffer, "", shrink: 2
    # ```
    #
    # The options available depend on the file format. Try something like:
    #
    # ```
    # $ vips jpegload_buffer
    # ```
    #
    # at the command-line to see the available options. Not all loaders
    # support load from buffer, but at least JPEG, PNG and
    # TIFF images will work.
    #
    # Loading is fast: only enough of the image is loaded to be able to fill
    # out the header. Pixels will only be decompressed when they are needed.
    #
    # @param data [String] the data to load from
    # @param option_string [String] load options as a string
    # @macro vips.loadopts
    # @return [Image] the loaded image
    def self.new_from_buffer data, option_string, **opts
      loader = Vips.vips_foreign_find_load_buffer data, data.bytesize
      raise Vips::Error if loader.nil?

      Vips::Operation.call loader, [data], opts, option_string
    end

    # Create a new {Image} from a C-style array held in memory. For example:
    #
    # ```
    # image = Vips::Image.black(16, 16) + 128
    # data = image.write_to_memory
    #
    # x = Vips::Image.new_from_memory data,
    #   image.width, image.height, image.bands, image.format
    # ```
    #
    # Creating a new image from a memory pointer:
    #
    # ```
    # ptr = FFI::MemoryPointer.new(:uchar, 10*10)
    # # => #<FFI::MemoryPointer address=0x00007fc236db31d0 size=100>
    # x = Vips::Image.new_from_memory(ptr, 10, 10, 1, :uchar)
    # ```
    #
    # Creating a new image from an address only pointer:
    #
    # ```
    # ptr = call_to_external_c_library(w: 10, h: 10)
    # # => #<FFI::Pointer address=0x00007f9780813a00>
    # ptr_slice = ptr.slice(0, 10*10)
    # # => #<FFI::Pointer address=0x00007f9780813a00 size=100>
    # x = Vips::Image.new_from_memory(ptr_slice, 10, 10, 1, :uchar)
    # ```
    #
    # {new_from_memory} keeps a reference to the array of pixels you pass in
    # to try to prevent that memory from being freed by the Ruby GC while it
    # is being used.
    #
    # See {new_from_memory_copy} for a version of this method which does not
    # keep a reference.
    #
    # @param data [String, FFI::Pointer] the data to load from
    # @param width [Integer] width in pixels
    # @param height [Integer] height in pixels
    # @param bands [Integer] number of bands
    # @param format [Symbol] band format
    # @return [Image] the loaded image
    def self.new_from_memory data, width, height, bands, format
      # prevent data from being freed with JRuby FFI
      if defined?(JRUBY_VERSION) && !data.is_a?(FFI::Pointer)
        data = ::FFI::MemoryPointer.new(:char, data.bytesize).write_bytes data
      end

      if data.is_a?(FFI::Pointer)
        # A pointer needs to know about the size of the memory it points to.
        # If you have an address-only pointer, use the .slice method to wrap
        # the pointer in a size aware pointer.
        if data.size == UNKNOWN_POINTER_SIZE
          raise Vips::Error, "size of memory is unknown"
        end
        size = data.size
      else
        size = data.bytesize
      end

      format_number = GObject::GValue.from_nick BAND_FORMAT_TYPE, format
      vi = Vips.vips_image_new_from_memory data, size,
        width, height, bands, format_number
      raise Vips::Error if vi.null?
      image = new(vi)

      # keep a secret ref to the underlying object .. this reference will be
      # inherited by things that in turn depend on us, so the memory we are
      # using will not be freed
      image.references << data

      image
    end

    # Create a new {Image} from memory and copies the memory area. See
    # {new_from_memory} for a version of this method which does not copy the
    # memory area.
    #
    # @param data [String, FFI::Pointer] the data to load from
    # @param width [Integer] width in pixels
    # @param height [Integer] height in pixels
    # @param bands [Integer] number of bands
    # @param format [Symbol] band format
    # @return [Image] the loaded image
    def self.new_from_memory_copy data, width, height, bands, format
      format_number = GObject::GValue.from_nick BAND_FORMAT_TYPE, format

      if data.is_a?(FFI::Pointer)
        if data.size == UNKNOWN_POINTER_SIZE
          raise Vips::Error, "size of memory is unknown"
        end
        size = data.size
      else
        size = data.bytesize
      end

      vi = Vips.vips_image_new_from_memory_copy data, size,
        width, height, bands, format_number
      raise Vips::Error if vi.null?
      new(vi)
    end

    # Create a new {Image} from a source. Load options may be passed as
    # strings or appended as a hash. For example:
    #
    # ```
    # source = Vips::Source.new_from_file("k2.jpg")
    # image = Vips::Image.new_from_source source, "shrink=2"
    # ```
    #
    # or alternatively:
    #
    # ```
    # image = Vips::Image.new_from_source source, "", shrink: 2
    # ```
    #
    # The options available depend on the file format. Try something like:
    #
    # ```
    # $ vips jpegload_source
    # ```
    #
    # at the command-line to see the available options. Not all loaders
    # support load from source, but at least JPEG, PNG and
    # TIFF images will work.
    #
    # Loading is fast: only enough data is read to be able to fill
    # out the header. Pixels will only be read and decompressed when they are
    # needed.
    #
    # @param source [Vips::Source] the source to load from
    # @param option_string [String] load options as a string
    # @macro vips.loadopts
    # @return [Image] the loaded image
    def self.new_from_source source, option_string, **opts
      loader = Vips.vips_foreign_find_load_source source
      raise Vips::Error if loader.nil?

      Vips::Operation.call loader, [source], opts, option_string
    end

    def self.matrix_from_array width, height, array
      ptr = FFI::MemoryPointer.new :double, array.length
      ptr.write_array_of_double array
      image = Vips.vips_image_new_matrix_from_array width, height,
        ptr, array.length
      Vips::Image.new image
    end

    # Create a new Image from a 1D or 2D array. A 1D array becomes an
    # image with height 1. Use `scale` and `offset` to set the scale and
    # offset fields in the header. These are useful for integer
    # convolutions.
    #
    # For example:
    #
    # ```
    # image = Vips::Image.new_from_array [1, 2, 3]
    # ```
    #
    # or
    #
    # ```
    # image = Vips::Image.new_from_array [
    #     [-1, -1, -1],
    #     [-1, 16, -1],
    #     [-1, -1, -1]], 8
    # ```
    #
    # for a simple sharpening mask.
    #
    # @param array [Array] the pixel data as an array of numbers
    # @param scale [Real] the convolution scale
    # @param offset [Real] the convolution offset
    # @return [Image] the image
    def self.new_from_array array, scale = 1, offset = 0
      # we accept a 1D array and assume height == 1, or a 2D array
      # and check all lines are the same length
      unless array.is_a? Array
        raise Vips::Error, "Argument is not an array."
      end

      if array[0].is_a? Array
        height = array.length
        width = array[0].length
        unless array.all? { |x| x.is_a? Array }
          raise Vips::Error, "Not a 2D array."
        end
        unless array.all? { |x| x.length == width }
          raise Vips::Error, "Array not rectangular."
        end

        array = array.flatten
      else
        height = 1
        width = array.length
      end

      unless array.length == width * height
        raise Vips::Error, "Bad array dimensions."
      end

      unless array.all? { |x| x.is_a? Numeric }
        raise Vips::Error, "Not all array elements are Numeric."
      end

      image = Vips::Image.matrix_from_array width, height, array
      raise Vips::Error if image.nil?

      image.mutate do |mutable|
        # be careful to set them as double
        mutable.set_type! GObject::GDOUBLE_TYPE, "scale", scale.to_f
        mutable.set_type! GObject::GDOUBLE_TYPE, "offset", offset.to_f
      end
    end

    # A new image is created with the same width, height, format,
    # interpretation, resolution and offset as self, but with every pixel
    # set to the specified value.
    #
    # You can pass an array to make a many-band image, or a single value to
    # make a one-band image.
    #
    # @param value [Real, Array<Real>] value to put in each pixel
    # @return [Image] constant image
    def new_from_image value
      pixel = (Vips::Image.black(1, 1) + value).cast(format)
      image = pixel.embed 0, 0, width, height, extend: :copy
      image.copy interpretation: interpretation, xres: xres, yres: yres,
        xoffset: xoffset, yoffset: yoffset
    end

    # Write this image to a file. Save options may be encoded in the
    # filename or given as a hash. For example:
    #
    # ```
    # image.write_to_file "fred.jpg[Q=90]"
    # ```
    #
    # or equivalently:
    #
    # ```
    # image.write_to_file "fred.jpg", Q: 90
    # ```
    #
    # The full set of save options depend on the selected saver. Try
    # something like:
    #
    # ```
    # $ vips jpegsave
    # ```
    #
    # to see all the available options for JPEG save.
    #
    # @!macro [new] vips.saveopts
    #   @param opts [Hash] set of options
    #   @option opts [Boolean] :strip (false) Strip all metadata from image
    #   @option opts [Array<Float>] :background (0) Background colour to
    #     flatten alpha against, if necessary
    #
    # @param name [String] filename to write to
    def write_to_file name, **opts
      raise Vips::Error, "filename is nil" if name.nil?

      filename = Vips.p2str(Vips.vips_filename_get_filename(name))
      option_string = Vips.p2str(Vips.vips_filename_get_options(name))
      saver = Vips.vips_foreign_find_save filename
      raise Vips::Error if saver.nil?

      Vips::Operation.call saver, [self, filename], opts, option_string

      write_gc
    end

    # Write this image to a memory buffer. Save options may be encoded in
    # the format_string or given as a hash. For example:
    #
    # ```
    # buffer = image.write_to_buffer ".jpg[Q=90]"
    # ```
    #
    # or equivalently:
    #
    # ```
    # image.write_to_buffer ".jpg", Q: 90
    # ```
    #
    # The full set of save options depend on the selected saver. Try
    # something like:
    #
    # ```
    # $ vips jpegsave
    # ```
    #
    # to see all the available options for JPEG save.
    #
    # @param format_string [String] save format plus options
    # @macro vips.saveopts
    # @return [String] the image saved in the specified format
    def write_to_buffer format_string, **opts
      raise Vips::Error, "filename is nil" if format_string.nil?
      filename = Vips.p2str(Vips.vips_filename_get_filename(format_string))
      option_string = Vips.p2str(Vips.vips_filename_get_options(format_string))

      # try to save with the new target API first, only fall back to the old
      # buffer API if there's no target save for this filetype
      saver = nil
      if Vips.at_least_libvips?(8, 9)
        Vips.vips_error_freeze
        saver = Vips.vips_foreign_find_save_target filename
        Vips.vips_error_thaw
      end

      if !saver.nil?
        target = Vips::Target.new_to_memory
        Vips::Operation.call saver, [self, target], opts, option_string
        buffer = target.get("blob")
      else
        saver = Vips.vips_foreign_find_save_buffer filename
        raise Vips::Error if saver.nil?

        buffer = Vips::Operation.call saver, [self], opts, option_string
        raise Vips::Error if buffer.nil?
      end

      write_gc

      buffer
    end

    # Write this image to a target. Save options may be encoded in
    # the format_string or given as a hash. For example:
    #
    # ```ruby
    # target = Vips::Target.new_to_file "k2.jpg"
    # image.write_to_target target, ".jpg[Q=90]"
    # ```
    #
    # or equivalently:
    #
    # ```ruby
    # image.write_to_target target, ".jpg", Q: 90
    # ```
    #
    # The full set of save options depend on the selected saver. Try
    # something like:
    #
    # ```
    # $ vips jpegsave_target
    # ```
    #
    # to see all the available options for JPEG save.
    #
    # @param target [Vips::Target] the target to write to
    # @param format_string [String] save format plus string options
    # @macro vips.saveopts
    def write_to_target target, format_string, **opts
      raise Vips::Error, "filename is nil" if format_string.nil?
      filename = Vips.p2str(Vips.vips_filename_get_filename(format_string))
      option_string = Vips.p2str(Vips.vips_filename_get_options(format_string))
      saver = Vips.vips_foreign_find_save_target filename
      raise Vips::Error if saver.nil?

      Vips::Operation.call saver, [self, target], opts, option_string
      write_gc
    end

    # Write this image to a large memory buffer.
    #
    # @return [String] the pixels as a huge binary string
    def write_to_memory
      len = Vips::SizeStruct.new
      ptr = Vips.vips_image_write_to_memory self, len
      raise Vips::Error if ptr.nil?

      # wrap up as an autopointer
      ptr = FFI::AutoPointer.new(ptr, GLib::G_FREE)

      ptr.get_bytes 0, len[:value]
    end

    # Turn progress signalling on and off.
    #
    # If this is on, the most-downstream image from this image will issue
    # progress signals.
    #
    # @see Object#signal_connect
    # @param state [Boolean] progress signalling state
    def set_progress state
      Vips.vips_image_set_progress self, state
    end

    # Kill computation of this time.
    #
    # Set true to stop computation of this image. You can call this from a
    # progress handler, for example.
    #
    # @see Object#signal_connect
    # @param kill [Boolean] stop computation
    def set_kill kill
      Vips.vips_image_set_kill self, kill
    end

    # Get the `GType` of a metadata field. The result is 0 if no such field
    # exists.
    #
    # @see get
    # @param name [String] Metadata field to fetch
    # @return [Integer] GType
    def get_typeof name
      # on libvips before 8.5, property types must be searched first,
      # since vips_image_get_typeof returned built-in enums as int
      unless Vips.at_least_libvips?(8, 5)
        gtype = parent_get_typeof name
        return gtype if gtype != 0
      end

      Vips.vips_image_get_typeof self, name
    end

    # Get a metadata item from an image. Ruby types are constructed
    # automatically from the `GValue`, if possible.
    #
    # For example, you can read the ICC profile from an image like this:
    #
    # ```
    # profile = image.get "icc-profile-data"
    # ```
    #
    # and profile will be an array containing the profile.
    #
    # @param name [String] Metadata field to get
    # @return [Object] Value of field
    def get name
      # with old libvips, we must fetch properties (as opposed to
      # metadata) via VipsObject
      unless Vips.at_least_libvips?(8, 5)
        return super if parent_get_typeof(name) != 0
      end

      gvalue = GObject::GValue.alloc
      raise Vips::Error if Vips.vips_image_get(self, name, gvalue) != 0
      result = gvalue.get
      gvalue.unset

      result
    end

    # Get the names of all fields on an image. Use this to loop over all
    # image metadata.
    #
    # @return [[String]] array of field names
    def get_fields
      # vips_image_get_fields() was added in libvips 8.5
      return [] unless Vips.respond_to? :vips_image_get_fields

      array = Vips.vips_image_get_fields self

      names = []
      p = array
      until (q = p.read_pointer).null?
        names << q.read_string
        GLib.g_free q
        p += FFI::Type::POINTER.size
      end
      GLib.g_free array

      names
    end

    # Mutate an image with a block. Inside the block, you can call methods
    # which modify the image, such as setting or removing metadata, or
    # modifying pixels.
    #
    # For example:
    #
    # ```ruby
    # image = image.mutate do |x|
    #   (0 ... 1).step(0.01) do |i|
    #     x.draw_line! 255, x.width * i, 0, 0, x.height * (1 - i)
    #   end
    # end
    # ```
    #
    # See {MutableImage}.
    def mutate
      mutable = Vips::MutableImage.new self
      yield mutable
      mutable.image
    end

    # This method is deprecated.
    #
    # Please use {MutableImage#set_type!} instead.
    def set_type gtype, name, value
      gvalue = GObject::GValue.alloc
      gvalue.init gtype
      gvalue.set value
      Vips.vips_image_set self, name, gvalue
      gvalue.unset
    end

    # This method is deprecated.
    #
    # Please use {MutableImage#set!} instead.
    def set name, value
      set_type get_typeof(name), name, value
    end

    # This method is deprecated.
    #
    # Please use {MutableImage#remove!} instead.
    def remove name
      Vips.vips_image_remove self, name
    end

    # compatibility: old name for get
    def get_value name
      get name
    end

    # This method is deprecated.
    #
    # Please use {MutableImage#set!} instead.
    def set_value name, value
      set name, value
    end

    # Get image width, in pixels.
    #
    # @return [Integer] image width, in pixels
    def width
      Vips.vips_image_get_width self
    end

    # Get image height, in pixels.
    #
    # @return [Integer] image height, in pixels
    def height
      Vips.vips_image_get_height self
    end

    # Get number of image bands.
    #
    # @return [Integer] number of image bands
    def bands
      Vips.vips_image_get_bands self
    end

    # Get image format.
    #
    # @return [Symbol] image format
    def format
      get "format"
    end

    # Get image interpretation.
    #
    # @return [Symbol] image interpretation
    def interpretation
      get "interpretation"
    end

    # Get image coding.
    #
    # @return [Symbol] image coding
    def coding
      get "coding"
    end

    # Get image filename, if any.
    #
    # @return [String] image filename
    def filename
      get "filename"
    end

    # Get image xoffset.
    #
    # @return [Integer] image xoffset
    def xoffset
      get "xoffset"
    end

    # Get image yoffset.
    #
    # @return [Integer] image yoffset
    def yoffset
      get "yoffset"
    end

    # Get image x resolution.
    #
    # @return [Float] image x resolution
    def xres
      get "xres"
    end

    # Get image y resolution.
    #
    # @return [Float] image y resolution
    def yres
      get "yres"
    end

    # Get scale metadata.
    #
    # @return [Float] image scale
    def scale
      return 1 if get_typeof("scale") == 0

      get "scale"
    end

    # Get offset metadata.
    #
    # @return [Float] image offset
    def offset
      return 0 if get_typeof("offset") == 0

      get "offset"
    end

    # Get the image size.
    #
    # @return [Integer, Integer] image width and height
    def size
      [width, height]
    end

    if Vips.at_least_libvips?(8, 5)
      # Detect if image has an alpha channel
      #
      # @return [Boolean] true if image has an alpha channel.
      def has_alpha?
        Vips.vips_image_hasalpha(self) != 0
      end
    end

    # vips_addalpha was added in libvips 8.6
    if Vips.at_least_libvips?(8, 6)
      # Append an alpha channel to an image.
      #
      # @return [Image] new image
      def add_alpha
        ptr = GenericPtr.new
        result = Vips.vips_addalpha self, ptr
        raise Vips::Error if result != 0

        Vips::Image.new ptr[:value]
      end
    end

    # Copy an image to a memory area.
    #
    # This can be useful for reusing results, but can obviously use a lot of
    # memory for large images. See {Image#tilecache} for a way of caching
    # parts of an image.
    #
    # @return [Image] new memory image
    def copy_memory
      new_image = Vips.vips_image_copy_memory self
      Vips::Image.new new_image
    end

    # Draw a point on an image.
    #
    # See {Image#draw_rect}.
    #
    # @return [Image] modified image
    def draw_point ink, left, top, **opts
      draw_rect ink, left, top, 1, 1, **opts
    end

    # Add an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] Thing to add to self
    # @return [Image] result of addition
    def + other
      other.is_a?(Vips::Image) ?
          add(other) : linear(1, other)
    end

    # Subtract an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] Thing to subtract from self
    # @return [Image] result of subtraction
    def - other
      other.is_a?(Vips::Image) ?
          subtract(other) : linear(1, Image.smap(other) { |x| x * -1 })
    end

    # Multiply an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] Thing to multiply by self
    # @return [Image] result of multiplication
    def * other
      other.is_a?(Vips::Image) ?
          multiply(other) : linear(other, 0)
    end

    # Divide an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] Thing to divide self by
    # @return [Image] result of division
    def / other
      other.is_a?(Vips::Image) ?
          divide(other) : linear(Image.smap(other) { |x| 1.0 / x }, 0)
    end

    # Remainder after integer division with an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] self modulo this
    # @return [Image] result of modulo
    def % other
      other.is_a?(Vips::Image) ?
          remainder(other) : remainder_const(other)
    end

    # Raise to power of an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] self to the power of this
    # @return [Image] result of power
    def ** other
      call_enum "math2", other, :pow
    end

    # Integer left shift with an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] shift left by this much
    # @return [Image] result of left shift
    def << other
      call_enum "boolean", other, :lshift
    end

    # Integer right shift with an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] shift right by this much
    # @return [Image] result of right shift
    def >> other
      call_enum "boolean", other, :rshift
    end

    # Integer bitwise OR with an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] bitwise OR with this
    # @return [Image] result of bitwise OR
    def | other
      call_enum "boolean", other, :or
    end

    # Integer bitwise AND with an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] bitwise AND with this
    # @return [Image] result of bitwise AND
    def & other
      call_enum "boolean", other, :and
    end

    # Integer bitwise EOR with an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] bitwise EOR with this
    # @return [Image] result of bitwise EOR
    def ^ other
      call_enum "boolean", other, :eor
    end

    # Equivalent to image ^ -1
    #
    # @return [Image] image with bits flipped
    def !
      self ^ -1
    end

    # Equivalent to image ^ -1
    #
    # @return [Image] image with bits flipped
    def ~
      self ^ -1
    end

    # @return [Image] image
    def +@
      self
    end

    # Equivalent to image * -1
    #
    # @return [Image] negative of image
    def -@
      self * -1
    end

    # Relational less than with an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] relational less than with this
    # @return [Image] result of less than
    def < other
      call_enum "relational", other, :less
    end

    # Relational less than or equal to with an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] relational less than or
    #   equal to with this
    # @return [Image] result of less than or equal to
    def <= other
      call_enum "relational", other, :lesseq
    end

    # Relational more than with an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] relational more than with this
    # @return [Image] result of more than
    def > other
      call_enum "relational", other, :more
    end

    # Relational more than or equal to with an image, constant or array.
    #
    # @param other [Image, Real, Array<Real>] relational more than or
    #   equal to with this
    # @return [Image] result of more than or equal to
    def >= other
      call_enum "relational", other, :moreeq
    end

    # Compare equality to nil, an image, constant or array.
    #
    # @param other [nil, Image, Real, Array<Real>] test equality to this
    # @return [Image] result of equality
    def == other
      # for equality, we must allow tests against nil
      if other.nil?
        false
      else
        call_enum "relational", other, :equal
      end
    end

    # Compare inequality to nil, an image, constant or array.
    #
    # @param other [nil, Image, Real, Array<Real>] test inequality to this
    # @return [Image] result of inequality
    def != other
      # for equality, we must allow tests against nil
      if other.nil?
        true
      else
        call_enum "relational", other, :noteq
      end
    end

    # Fetch bands using a number or a range
    #
    # @param index [Numeric, Range] extract these band(s)
    # @return [Image] extracted band(s)
    def [] index
      if index.is_a? Range
        n = index.size
        extract_band index.begin, n: n
      elsif index.is_a? Numeric
        extract_band index
      else
        raise Vips::Error, "[] index is not range or numeric."
      end
    end

    # Convert to an Enumerator. Similar to `#to_a` but lazier.
    #
    # @return [Enumerator] Enumerator of Enumerators of Arrays of Numerics
    def to_enum
      # make the template for unpack
      template = {
        char: "c",
        uchar: "C",
        short: "s_",
        ushort: "S_",
        int: "i_",
        uint: "I_",
        float: "f",
        double: "d",
        complex: "f",
        dpcomplex: "d"
      }[format] + "*"

      # we render the image to a big string, then unpack into
      # one-dimensional array as a Ruby array of the correct type
      array = write_to_memory.unpack template

      # gather bands of a pixel together
      pixel_array = array.each_slice bands

      # gather pixels of a row together
      pixel_array.each_slice width
    end

    # Convert to an Array. This will be slow for large images.
    #
    # @return [Array] Array of Arrays of Arrays of Numerics
    def to_a
      to_enum.to_a
    end

    # Return the largest integral value not greater than the argument.
    #
    # @return [Image] floor of image
    def floor
      round :floor
    end

    # Return the smallest integral value not less than the argument.
    #
    # @return [Image] ceil of image
    def ceil
      round :ceil
    end

    # Return the nearest integral value.
    #
    # @return [Image] rint of image
    def rint
      round :rint
    end

    # AND the bands of an image together
    #
    # @return [Image] all bands ANDed together
    def bandand
      bandbool :and
    end

    # OR the bands of an image together
    #
    # @return [Image] all bands ORed together
    def bandor
      bandbool :or
    end

    # EOR the bands of an image together
    #
    # @return [Image] all bands EORed together
    def bandeor
      bandbool :eor
    end

    # Split an n-band image into n separate images.
    #
    # @return [Array<Image>] Array of n one-band images
    def bandsplit
      (0...bands).map { |i| extract_band i }
    end

    # Join a set of images bandwise.
    #
    # @param other [Image, Array<Image>, Real, Array<Real>] bands to append
    # @return [Image] many band image
    def bandjoin other
      unless other.is_a? Array
        other = [other]
      end

      # if other is just Numeric, we can use bandjoin_const
      not_all_real = !other.all? { |x| x.is_a? Numeric }

      if not_all_real
        Vips::Image.bandjoin([self] + other)
      else
        bandjoin_const other
      end
    end

    # Composite a set of images with a set of blend modes.
    #
    # @param overlay [Image, Array<Image>] images to composite
    # @param mode [BlendMode, Array<BlendMode>] blend modes to use
    # @param opts [Hash] Set of options
    # @option opts [Array<Integer>] :x x positions of overlay
    # @option opts [Array<Integer>] :y y positions of overlay
    # @option opts [Vips::Interpretation] :compositing_space Composite images
    #     in this colour space
    # @option opts [Boolean] :premultiplied Images have premultiplied alpha
    # @return [Image] blended image
    def composite overlay, mode, **opts
      unless overlay.is_a? Array
        overlay = [overlay]
      end
      unless mode.is_a? Array
        mode = [mode]
      end

      mode = mode.map do |x|
        GObject::GValue.from_nick Vips::BLEND_MODE_TYPE, x
      end

      Vips::Image.composite([self] + overlay, mode, **opts)
    end

    # Return the coordinates of the image maximum.
    #
    # @return [Real, Real, Real] maximum value, x coordinate of maximum, y
    #   coordinate of maximum
    def maxpos
      v, opts = max x: true, y: true
      x = opts["x"]
      y = opts["y"]
      [v, x, y]
    end

    # Return the coordinates of the image minimum.
    #
    # @return [Real, Real, Real] minimum value, x coordinate of minimum, y
    #   coordinate of minimum
    def minpos
      v, opts = min x: true, y: true
      x = opts["x"]
      y = opts["y"]
      [v, x, y]
    end

    # a median filter
    #
    # @param size [Integer] size of filter window
    # @return [Image] result of median filter
    def median size = 3
      rank size, size, size**2 / 2
    end

    # Return the real part of a complex image.
    #
    # @return [Image] real part of complex image
    def real
      complexget :real
    end

    # Return the imaginary part of a complex image.
    #
    # @return [Image] imaginary part of complex image
    def imag
      complexget :imag
    end

    # Return an image with rectangular pixels converted to polar.
    #
    # The image
    # can be complex, in which case the return image will also be complex,
    # or must have an even number of bands, in which case pairs of
    # bands are treated as (x, y) coordinates.
    #
    # @see xyz
    # @return [Image] image converted to polar coordinates
    def polar
      Image.run_cmplx(self) { |x| x.complex :polar }
    end

    # Return an image with polar pixels converted to rectangular.
    #
    # The image
    # can be complex, in which case the return image will also be complex,
    # or must have an even number of bands, in which case pairs of
    # bands are treated as (x, y) coordinates.
    #
    # @see xyz
    # @return [Image] image converted to rectangular coordinates
    def rect
      Image.run_cmplx(self) { |x| x.complex :rect }
    end

    # Return the complex conjugate of an image.
    #
    # The image
    # can be complex, in which case the return image will also be complex,
    # or must have an even number of bands, in which case pairs of
    # bands are treated as (x, y) coordinates.
    #
    # @return [Image] complex conjugate
    def conj
      Image.run_cmplx(self) { |x| x.complex :conj }
    end

    # Calculate the cross phase of two images.
    #
    # @param other [Image, Real, Array<Real>] cross phase with this
    # @return [Image] cross phase
    def cross_phase other
      complex2 other, :cross_phase
    end

    # Return the sine of an image in degrees.
    #
    # @return [Image] sine of each pixel
    def sin
      math :sin
    end

    # Return the cosine of an image in degrees.
    #
    # @return [Image] cosine of each pixel
    def cos
      math :cos
    end

    # Return the tangent of an image in degrees.
    #
    # @return [Image] tangent of each pixel
    def tan
      math :tan
    end

    # Return the inverse sine of an image in degrees.
    #
    # @return [Image] inverse sine of each pixel
    def asin
      math :asin
    end

    # Return the inverse cosine of an image in degrees.
    #
    # @return [Image] inverse cosine of each pixel
    def acos
      math :acos
    end

    # Return the inverse tangent of an image in degrees.
    #
    # @return [Image] inverse tangent of each pixel
    def atan
      math :atan
    end

    # Return the hyperbolic sine of an image in radians.
    #
    # @return [Image] sine of each pixel
    def sinh
      math :sinh
    end

    # Return the hyperbolic cosine of an image in radians.
    #
    # @return [Image] cosine of each pixel
    def cosh
      math :cosh
    end

    # Return the hyperbolic tangent of an image in radians.
    #
    # @return [Image] tangent of each pixel
    def tanh
      math :tanh
    end

    # Return the inverse hyperbolic sine of an image in radians.
    #
    # @return [Image] inverse sine of each pixel
    def asinh
      math :asinh
    end

    # Return the inverse hyperbolic cosine of an image in radians.
    #
    # @return [Image] inverse cosine of each pixel
    def acosh
      math :acosh
    end

    # Return the inverse hyperbolic tangent of an image in radians.
    #
    # @return [Image] inverse tangent of each pixel
    def atanh
      math :atanh
    end

    # Return the natural log of an image.
    #
    # @return [Image] natural log of each pixel
    def log
      math :log
    end

    # Return the log base 10 of an image.
    #
    # @return [Image] base 10 log of each pixel
    def log10
      math :log10
    end

    # Return e ** pixel.
    #
    # @return [Image] e ** pixel
    def exp
      math :exp
    end

    # Return 10 ** pixel.
    #
    # @return [Image] 10 ** pixel
    def exp10
      math :exp10
    end

    # Flip horizontally.
    #
    # @return [Image] image flipped horizontally
    def fliphor
      flip :horizontal
    end

    # Flip vertically.
    #
    # @return [Image] image flipped vertically
    def flipver
      flip :vertical
    end

    # Erode with a structuring element.
    #
    # The structuring element must be an array with 0 for black, 255 for
    # white and 128 for don't care.
    #
    # @param mask [Image, Array<Real>, Array<Array<Real>>] structuring
    #   element
    # @return [Image] eroded image
    def erode mask
      morph mask, :erode
    end

    # Dilate with a structuring element.
    #
    # The structuring element must be an array with 0 for black, 255 for
    # white and 128 for don't care.
    #
    # @param mask [Image, Array<Real>, Array<Array<Real>>] structuring
    #   element
    # @return [Image] dilated image
    def dilate mask
      morph mask, :dilate
    end

    # Rotate by 90 degrees clockwise.
    #
    # @return [Image] rotated image
    def rot90
      rot :d90
    end

    # Rotate by 180 degrees clockwise.
    #
    # @return [Image] rotated image
    def rot180
      rot :d180
    end

    # Rotate by 270 degrees clockwise.
    #
    # @return [Image] rotated image
    def rot270
      rot :d270
    end

    # Select pixels from `th` if `self` is non-zero and from `el` if
    # `self` is zero. Use the `:blend` option to fade smoothly
    # between `th` and `el`.
    #
    # @param th [Image, Real, Array<Real>] true values
    # @param el [Image, Real, Array<Real>] false values
    # @param opts [Hash] set of options
    # @option opts [Boolean] :blend (false) Blend smoothly between th and el
    # @return [Image] merged image
    def ifthenelse(th, el, **opts)
      match_image = [th, el, self].find { |x| x.is_a? Vips::Image }

      unless th.is_a? Vips::Image
        th = Operation.imageize match_image, th
      end
      unless el.is_a? Vips::Image
        el = Operation.imageize match_image, el
      end

      Vips::Operation.call "ifthenelse", [self, th, el], opts
    end

    # Scale an image to uchar. This is the vips `scale` operation, but
    # renamed to avoid a clash with the `.scale` property.
    #
    # @param opts [Hash] Set of options
    # @return [Vips::Image] Output image
    def scaleimage **opts
      Vips::Image.scale self, **opts
    end
  end
end

module Vips
  # This module generates yard comments for all the dynamically bound
  # vips operations.
  #
  # Regenerate with something like:
  #
  # ```
  # $ ruby > methods.rb
  # require "vips"; Vips::Yard.generate
  # ^D
  # ```

  module Yard
    # map gobject's type names to Ruby
    MAP_GO_TO_RUBY = {
      "gboolean" => "Boolean",
      "gint" => "Integer",
      "gdouble" => "Float",
      "gfloat" => "Float",
      "gchararray" => "String",
      "VipsImage" => "Vips::Image",
      "VipsInterpolate" => "Vips::Interpolate",
      "VipsConnection" => "Vips::Connection",
      "VipsSource" => "Vips::Source",
      "VipsTarget" => "Vips::Target",
      "VipsSourceCustom" => "Vips::SourceCustom",
      "VipsTargetCustom" => "Vips::TargetCustom",
      "VipsArrayDouble" => "Array<Double>",
      "VipsArrayInt" => "Array<Integer>",
      "VipsArrayImage" => "Array<Image>",
      "VipsArrayString" => "Array<String>"
    }

    # these have hand-written methods, see above
    NO_GENERATE = ["scale", "bandjoin", "composite", "ifthenelse"]

    # these are aliased (appear under several names)
    ALIAS = ["crop"]

    # turn a gtype into a ruby type name
    def self.gtype_to_ruby gtype
      fundamental = GObject.g_type_fundamental gtype
      type_name = GObject.g_type_name gtype

      if MAP_GO_TO_RUBY.include? type_name
        type_name = MAP_GO_TO_RUBY[type_name]
      end

      if fundamental == GObject::GFLAGS_TYPE ||
          fundamental == GObject::GENUM_TYPE
        type_name = "Vips::" + type_name[/Vips(.*)/, 1]
      end

      type_name
    end

    def self.generate_operation introspect
      return if (introspect.flags & OPERATION_DEPRECATED) != 0
      return if NO_GENERATE.include? introspect.name

      method_args = introspect.method_args
      required_output = introspect.required_output
      optional_input = introspect.doc_optional_input
      optional_output = introspect.doc_optional_output

      print "# @!method "
      print "self." unless introspect.member_x
      print "#{introspect.name}("
      print method_args.map { |x| x[:yard_name] }.join(", ")
      print ", " if method_args.length > 0
      puts "**opts)"

      puts "#   #{introspect.description.capitalize}."

      method_args.each do |details|
        yard_name = details[:yard_name]
        gtype = details[:gtype]
        blurb = details[:blurb]

        puts "#   @param #{yard_name} [#{gtype_to_ruby(gtype)}] #{blurb}"
      end

      puts "#   @param opts [Hash] Set of options"
      optional_input.each do |arg_name, details|
        yard_name = details[:yard_name]
        gtype = details[:gtype]
        rtype = gtype_to_ruby gtype
        blurb = details[:blurb]

        puts "#   @option opts [#{rtype}] :#{yard_name} #{blurb}"
      end
      optional_output.each do |arg_name, details|
        yard_name = details[:yard_name]
        gtype = details[:gtype]
        rtype = gtype_to_ruby gtype
        blurb = details[:blurb]

        puts "#   @option opts [#{rtype}] :#{yard_name} Output #{blurb}"
      end

      print "#   @return ["
      if required_output.length == 0
        print "nil"
      elsif required_output.length == 1
        print gtype_to_ruby(required_output.first[:gtype])
      else
        print "Array<"
        print required_output.map { |x| gtype_to_ruby(x[:gtype]) }.join(", ")
        print ">"
      end
      if optional_output.length > 0
        print ", Hash<Symbol => Object>"
      end
      print "] "
      print required_output.map { |x| x[:blurb] }.join(", ")
      if optional_output.length > 0
        print ", " if required_output.length > 0
        print "Hash of optional output items"
      end
      puts ""

      puts ""
    end

    def self.generate
      alias_gtypes = {}
      ALIAS.each do |name|
        gtype = Vips.type_find "VipsOperation", name
        alias_gtypes[gtype] = name
      end

      generate_class = lambda do |gtype, _|
        name = if alias_gtypes.key? gtype
          alias_gtypes[gtype]
        else
          Vips.nickname_find gtype
        end

        if name
          begin
            # can fail for abstract types
            introspect = Vips::Introspect.get_yard name
          rescue Vips::Error
            nil
          end

          generate_operation(introspect) if introspect
        end

        Vips.vips_type_map gtype, generate_class, nil
      end

      puts "module Vips"
      puts "  class Image"
      puts ""

      generate_class.call(GObject.g_type_from_name("VipsOperation"), nil)

      puts "  end"
      puts "end"
    end
  end
end
