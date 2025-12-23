# This module provides an interface to the vips image processing library
# via ruby-ffi.
#
# Author::    John Cupitt  (mailto:jcupitt@gmail.com)
# License::   MIT

require "ffi"
require "forwardable"

module Vips
  # This class represents a libvips image which can be modified. See
  # {Vips::Image#mutate}.
  class MutableImage < Vips::Object
    extend Forwardable
    alias_method :parent_get_typeof, :get_typeof
    def_instance_delegators :@image, :width, :height, :bands, :format,
      :interpretation, :filename, :xoffset, :yoffset, :xres, :yres, :size,
      :get, :get_typeof, :get_fields

    # layout is exactly as {Image} (since we are also wrapping a VipsImage
    # object)
    module MutableImageLayout
      def self.included base
        base.class_eval do
          layout :parent, Vips::Object::Struct
          # rest opaque
        end
      end
    end

    class Struct < Vips::Object::Struct
      include MutableImageLayout
    end

    class ManagedStruct < Vips::Object::ManagedStruct
      include MutableImageLayout
    end

    # Get the {Image} this {MutableImage} is modifying. Only use this once you
    # have finished all modifications.
    #
    # This is for internal use only. See {Vips::Image#mutate} for the
    # user-facing interface.
    attr_reader :image

    # Make a {MutableImage} from a regular {Image}.
    #
    # This is for internal use only. See {Vips::Image#mutate} for the
    # user-facing interface.
    def initialize(image)
      # We take a copy of the regular Image to ensure we have an unshared
      # (unique) object. We forward things like #width and #height to this, and
      # it's the thing we return at the end of the mutate block.
      copy_image = image.copy

      # Use ptr since we need the raw unwrapped pointer inside the image ...
      # and make the ref that gobject will unref when it finishes.
      # See also the comment on set_type! before changing this.
      pointer = copy_image.ptr
      ::GObject.g_object_ref pointer
      super pointer

      # and save the copy ready for when we finish mutating
      @image = copy_image
    end

    def inspect
      "#<MutableImage #{width}x#{height} #{format}, #{bands} bands, #{interpretation}>"
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
      # Respond to all vips operations by nickname.
      return true if Vips.type_find("VipsOperation", name.to_s) != 0

      super
    end

    # Invoke a vips operation with {Vips::Operation#call}, using self as
    # the first input argument. {Vips::Operation#call} will only allow
    # operations that modify self when passed a {MutableImage}.
    #
    # @param name [String] vips operation to call
    # @return result of vips operation
    def method_missing name, *args, **options
      Vips::Operation.call name.to_s, [self, *args], options
    end

    # Create a metadata item on an image of the specifed type. Ruby types
    # are automatically transformed into the matching glib type (eg.
    # {GObject::GINT_TYPE}), if possible.
    #
    # For example, you can use this to set an image's ICC profile:
    #
    # ```ruby
    # x.set_type! Vips::BLOB_TYPE, "icc-profile-data", profile
    # ```
    #
    # where `profile` is an ICC profile held as a binary string object.
    #
    # @see set!
    # @param gtype [Integer] GType of item
    # @param name [String] Metadata field to set
    # @param value [Object] Value to set
    def set_type! gtype, name, value
      gvalue = GObject::GValue.alloc
      gvalue.init gtype
      gvalue.set value

      # libvips 8.9.1 had a terrible misfeature which would block metadata
      # modification unless the object had a ref_count of 1. MutableImage
      # will always have a ref_count of at least 2 (the parent gobject keeps a
      # ref, and we keep a ref to the copy ready to return to our caller),
      # so we must temporarily drop the refs to 1 around metadata changes.
      #
      # See https://github.com/libvips/ruby-vips/issues/291
      begin
        ::GObject.g_object_unref ptr
        Vips.vips_image_set self, name, gvalue
      ensure
        ::GObject.g_object_ref ptr
      end

      gvalue.unset
    end

    # Set the value of a metadata item on an image. The metadata item must
    # already exist. Ruby types are automatically transformed into the
    # matching {GObject::GValue}, if possible.
    #
    # For example, you can use this to set an image's ICC profile:
    #
    # ```
    # x.set! "icc-profile-data", profile
    # ```
    #
    # where `profile` is an ICC profile held as a binary string object.
    #
    # @see set_type!
    # @param name [String] Metadata field to set
    # @param value [Object] Value to set
    def set! name, value
      set_type! get_typeof(name), name, value
    end

    # Remove a metadata item from an image.
    #
    # For example:
    #
    # ```
    # x.remove! "icc-profile-data"
    # ```
    #
    # @param name [String] Metadata field to remove
    def remove! name
      # See set_type! for an explanation. Image#remove can't throw an
      # exception, so there's no need to ensure we unref.
      ::GObject.g_object_unref ptr
      Vips.vips_image_remove self, name
      ::GObject.g_object_ref ptr
    end
  end
end
