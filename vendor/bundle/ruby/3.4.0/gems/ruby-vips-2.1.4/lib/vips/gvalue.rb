# This module provides an interface GValue via ruby-ffi.
#
# Author::    John Cupitt  (mailto:jcupitt@gmail.com)
# License::   MIT

require "ffi"

module GObject
  # Represent a GValue. Example use:
  #
  # ```ruby
  # gvalue = GValue::alloc
  # gvalue.init GObject::GDOUBLE_TYPE
  # gvalue.set 3.1415
  # value = gvalue.get
  # # optional -- drop any ref the gvalue had
  # gvalue.unset
  # ```
  #
  # Lifetime is managed automatically. It doesn't know about all GType values,
  # but it does know the ones that libvips uses.

  class GValue < FFI::ManagedStruct
    layout :gtype, :GType,
      :data, [:ulong_long, 2]

    # convert an enum value (str/symb/int) into an int ready for libvips
    def self.from_nick(gtype, value)
      value = value.to_s if value.is_a? Symbol

      if value.is_a? String
        # libvips expects "-" as a separator in enum names, but "_" is more
        # convenient for ruby, eg. :b_w
        value = Vips.vips_enum_from_nick "ruby-vips", gtype, value.tr("_", "-")
        if value == -1
          raise Vips::Error
        end
      end

      value
    end

    # convert an int enum back into a symbol
    def self.to_nick(gtype, enum_value)
      enum_name = Vips.vips_enum_nick gtype, enum_value
      if enum_name.nil?
        raise Vips::Error
      end

      enum_name.to_sym
    end

    def self.release ptr
      # GLib::logger.debug("GObject::GValue::release") {"ptr = #{ptr}"}
      ::GObject.g_value_unset ptr
    end

    # Allocate memory for a GValue and return a class wrapper. Memory will
    # be freed automatically when it goes out of scope. The GValue is inited
    # to 0, use {GValue.init} to set a type.
    #
    # @return [GValue] a new gvalue set to 0
    def self.alloc
      # allocate memory
      memory = FFI::MemoryPointer.new GValue

      # make this alloc autorelease ... we mustn't release in
      # GValue::release, since we are used to wrap GValue pointers
      # made by other people
      pointer = FFI::Pointer.new GValue, memory

      # ... and wrap in a GValue
      GValue.new pointer
    end

    # Set the type of thing a gvalue can hold.
    #
    # @param gtype [GType] the type of thing this GValue can hold.
    def init gtype
      ::GObject.g_value_init self, gtype
    end

    # Set the value of a GValue. The value is converted to the type of the
    # GValue, if possible.
    #
    # @param value [Any] The value to set
    def set value
      # GLib::logger.debug("GObject::GValue.set") {
      #     "value = #{value.inspect[0..50]}"
      # }

      gtype = self[:gtype]
      fundamental = ::GObject.g_type_fundamental gtype

      case gtype
      when GBOOL_TYPE
        ::GObject.g_value_set_boolean self, (value ? 1 : 0)

      when GINT_TYPE
        ::GObject.g_value_set_int self, value

      when GUINT64_TYPE
        ::GObject.g_value_set_uint64 self, value

      when GDOUBLE_TYPE
        ::GObject.g_value_set_double self, value

      when GSTR_TYPE
        ::GObject.g_value_set_string self, value

      when Vips::REFSTR_TYPE
        ::Vips.vips_value_set_ref_string self, value

      when Vips::ARRAY_INT_TYPE
        value = [value] unless value.is_a? Array

        Vips.vips_value_set_array_int self, nil, value.length
        ptr = Vips.vips_value_get_array_int self, nil
        ptr.write_array_of_int32 value

      when Vips::ARRAY_DOUBLE_TYPE
        value = [value] unless value.is_a? Array

        # this will allocate an array in the gvalue
        Vips.vips_value_set_array_double self, nil, value.length

        # pull the array out and fill it
        ptr = Vips.vips_value_get_array_double self, nil

        ptr.write_array_of_double value

      when Vips::ARRAY_IMAGE_TYPE
        value = [value] unless value.is_a? Array

        Vips.vips_value_set_array_image self, value.length
        ptr = Vips.vips_value_get_array_image self, nil
        ptr.write_array_of_pointer value

        # the gvalue needs a ref on each of the images
        value.each { |image| ::GObject.g_object_ref image }

      when Vips::BLOB_TYPE
        len = value.bytesize
        ptr = GLib.g_malloc len
        Vips.vips_value_set_blob self, GLib::G_FREE, ptr, len
        ptr.write_bytes value

      else
        case fundamental
        when GFLAGS_TYPE
          ::GObject.g_value_set_flags self, value

        when GENUM_TYPE
          enum_value = GValue.from_nick(self[:gtype], value)
          ::GObject.g_value_set_enum self, enum_value

        when GOBJECT_TYPE
          ::GObject.g_value_set_object self, value

        else
          raise Vips::Error, "unimplemented gtype for set: " \
            "#{::GObject.g_type_name gtype} (#{gtype})"
        end
      end
    end

    # Get the value of a GValue. The value is converted to a Ruby type in
    # the obvious way.
    #
    # @return [Any] the value held by the GValue
    def get
      gtype = self[:gtype]
      fundamental = ::GObject.g_type_fundamental gtype
      result = nil

      case gtype
      when GBOOL_TYPE
        result = ::GObject.g_value_get_boolean(self) != 0

      when GINT_TYPE
        result = ::GObject.g_value_get_int self

      when GUINT64_TYPE
        result = ::GObject.g_value_get_uint64 self

      when GDOUBLE_TYPE
        result = ::GObject.g_value_get_double self

      when GSTR_TYPE
        result = ::GObject.g_value_get_string self

      when Vips::REFSTR_TYPE
        len = Vips::SizeStruct.new
        result = ::Vips.vips_value_get_ref_string self, len

      when Vips::ARRAY_INT_TYPE
        len = Vips::IntStruct.new
        array = Vips.vips_value_get_array_int self, len
        result = array.get_array_of_int32 0, len[:value]

      when Vips::ARRAY_DOUBLE_TYPE
        len = Vips::IntStruct.new
        array = Vips.vips_value_get_array_double self, len
        result = array.get_array_of_double 0, len[:value]

      when Vips::ARRAY_IMAGE_TYPE
        len = Vips::IntStruct.new
        array = Vips.vips_value_get_array_image self, len
        result = array.get_array_of_pointer 0, len[:value]
        result.map! do |pointer|
          ::GObject.g_object_ref pointer
          Vips::Image.new pointer
        end

      when Vips::BLOB_TYPE
        len = Vips::SizeStruct.new
        array = Vips.vips_value_get_blob self, len
        result = array.get_bytes 0, len[:value]

      else
        case fundamental
        when GFLAGS_TYPE
          result = ::GObject.g_value_get_flags self

        when GENUM_TYPE
          enum_value = ::GObject.g_value_get_enum(self)
          result = GValue.to_nick self[:gtype], enum_value

        when GOBJECT_TYPE
          obj = ::GObject.g_value_get_object self
          # g_value_get_object() does not add a ref ... we need to add
          # one to match the unref in gobject release
          ::GObject.g_object_ref obj
          result = Vips::Image.new obj

        else
          raise Vips::Error, "unimplemented gtype for get: " \
            "#{::GObject.g_type_name gtype} (#{gtype})"
        end
      end

      # GLib::logger.debug("GObject::GValue.get") {
      #     "result = #{result.inspect[0..50]}"
      # }

      result
    end

    # Clear the thing held by a GValue.
    #
    # This happens automatically when a GValue is GCed, but this method can be
    # handy if you need to drop a reference explicitly for some reason.
    def unset
      ::GObject.g_value_unset self
    end
  end

  attach_function :g_value_init, [GValue.ptr, :GType], :void

  # we must use a plain :pointer here, since we call this from #release, which
  # just gives us the unwrapped pointer, not the ruby class
  attach_function :g_value_unset, [:pointer], :void

  attach_function :g_value_set_boolean, [GValue.ptr, :int], :void
  attach_function :g_value_set_int, [GValue.ptr, :int], :void
  attach_function :g_value_set_uint64, [GValue.ptr, :uint64], :void
  attach_function :g_value_set_double, [GValue.ptr, :double], :void
  attach_function :g_value_set_enum, [GValue.ptr, :int], :void
  attach_function :g_value_set_flags, [GValue.ptr, :uint], :void
  attach_function :g_value_set_string, [GValue.ptr, :string], :void
  attach_function :g_value_set_object, [GValue.ptr, :pointer], :void

  attach_function :g_value_get_boolean, [GValue.ptr], :int
  attach_function :g_value_get_int, [GValue.ptr], :int
  attach_function :g_value_get_uint64, [GValue.ptr], :uint64
  attach_function :g_value_get_double, [GValue.ptr], :double
  attach_function :g_value_get_enum, [GValue.ptr], :int
  attach_function :g_value_get_flags, [GValue.ptr], :int
  attach_function :g_value_get_string, [GValue.ptr], :string
  attach_function :g_value_get_object, [GValue.ptr], :pointer

  # use :pointer rather than GObject.ptr to avoid casting later
  attach_function :g_object_set_property,
    [:pointer, :string, GValue.ptr], :void
  attach_function :g_object_get_property,
    [:pointer, :string, GValue.ptr], :void
end
