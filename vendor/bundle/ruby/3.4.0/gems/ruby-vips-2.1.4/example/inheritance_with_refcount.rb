#!/usr/bin/ruby

require "ffi"
require "forwardable"

# this is really very crude logging

# @private
$vips_debug = true

# @private
def log str
  if $vips_debug
    puts str
  end
end

def set_debug debug
  $vips_debug = debug
end

module Libc
  extend FFI::Library
  ffi_lib FFI::Library::LIBC

  attach_function :malloc, [:size_t], :pointer
  attach_function :free, [:pointer], :void
end

module GLib
  extend FFI::Library
  ffi_lib "gobject-2.0"

  def self.set_log_domain(_domain)
    # FIXME: this needs hooking up
  end

  # we have a set of things we need to inherit in different ways:
  #
  # - we want to be able to subclass GObject in a simple way
  # - the layouts of the nested structs
  # - casting between structs which share a base
  # - gobject refcounting
  #
  # the solution is to split the class into four areas which we treat
  # differently:
  #
  # - we have a "wrapper" Ruby class to allow easy subclassing ... this has a
  #   @struct member which holds the actual pointer
  # - we use "forwardable" to forward the various ffi methods on to the
  #   @struct member ... we arrange things so that subclasses do not need to
  #   do the forwarding themselves
  # - we have two versions of the struct: a plain one which we can use for
  #   casting that will not change the refcounts
  # - and a managed one with an unref which we just use for .new
  # - we separate the struct layout into a separate module to avoid repeating
  #   ourselves

  class GObject
    extend Forwardable
    extend SingleForwardable

    def_instance_delegators :@struct, :[], :to_ptr
    def_single_delegators :ffi_struct, :ptr

    # the layout of the GObject struct
    module GObjectLayout
      def self.included(base)
        base.class_eval do
          layout :g_type_instance, :pointer,
            :ref_count, :uint,
            :qdata, :pointer
        end
      end
    end

    # the struct with unref ... manage object lifetime with this
    class ManagedStruct < FFI::ManagedStruct
      include GObjectLayout

      def initialize(ptr)
        log "GLib::GObject::ManagedStruct.new: #{ptr}"
        super
      end

      def self.release(ptr)
        log "GLib::GObject::ManagedStruct.release: unreffing #{ptr}"
        GLib.g_object_unref(ptr) unless ptr.null?
      end
    end

    # the plain struct ... cast with this
    class Struct < FFI::Struct
      include GObjectLayout

      def initialize(ptr)
        log "GLib::GObject::Struct.new: #{ptr}"
        super
      end
    end

    # don't allow ptr == nil, we never want to allocate a GObject struct
    # ourselves, we just want to wrap GLib-allocated GObjects
    #
    # here we use ManagedStruct, not Struct, since this is the ref that will
    # need the unref
    def initialize(ptr)
      log "GLib::GObject.initialize: ptr = #{ptr}"
      @struct = ffi_managed_struct.new(ptr)
    end

    # access to the cast struct for this class
    def ffi_struct
      self.class.ffi_struct
    end

    class << self
      def ffi_struct
        const_get(:Struct)
      end
    end

    # access to the lifetime managed struct for this class
    def ffi_managed_struct
      self.class.ffi_managed_struct
    end

    class << self
      def ffi_managed_struct
        const_get(:ManagedStruct)
      end
    end
  end

  # we can't just use ulong, windows has different int sizing rules
  if FFI::Platform::ADDRESS_SIZE == 64
    typedef :uint64, :GType
  else
    typedef :uint32, :GType
  end
end

module Vips
  extend FFI::Library
  ffi_lib "vips"

  LOG_DOMAIN = "VIPS"
  GLib.set_log_domain(LOG_DOMAIN)

  # need to repeat this
  if FFI::Platform::ADDRESS_SIZE == 64
    typedef :uint64, :GType
  else
    typedef :uint32, :GType
  end

  attach_function :vips_init, [:string], :int
  attach_function :vips_shutdown, [], :void

  attach_function :vips_error_buffer, [], :string
  attach_function :vips_error_clear, [], :void

  def self.get_error
    errstr = Vips.vips_error_buffer
    Vips.vips_error_clear
    errstr
  end

  if Vips.vips_init($0) != 0
    puts Vips.get_error
    exit 1
  end

  at_exit do
    Vips.vips_shutdown
  end

  attach_function :vips_object_print_all, [], :void
  attach_function :vips_leak_set, [:int], :void

  def self.showall
    if $vips_debug
      GC.start
      vips_object_print_all
    end
  end

  if $vips_debug
    vips_leak_set 1
  end

  class VipsObject < GLib::GObject
    # the layout of the VipsObject struct
    module VipsObjectLayout
      def self.included(base)
        base.class_eval do
          # don't actually need most of these, remove them later
          layout :parent, GLib::GObject::Struct,
            :constructed, :int,
            :static_object, :int,
            :argument_table, :pointer,
            :nickname, :string,
            :description, :string,
            :preclose, :int,
            :close, :int,
            :postclose, :int,
            :local_memory, :size_t
        end
      end
    end

    class Struct < GLib::GObject::Struct
      include VipsObjectLayout

      def initialize(ptr)
        log "Vips::VipsObject::Struct.new: #{ptr}"
        super
      end
    end

    class ManagedStruct < GLib::GObject::ManagedStruct
      include VipsObjectLayout

      def initialize(ptr)
        log "Vips::VipsObject::ManagedStruct.new: #{ptr}"
        super
      end
    end
  end

  class VipsImage < VipsObject
    # the layout of the VipsImage struct
    module VipsImageLayout
      def self.included(base)
        base.class_eval do
          layout :parent, VipsObject::Struct
          # rest opaque
        end
      end
    end

    class Struct < VipsObject::Struct
      include VipsImageLayout

      def initialize(ptr)
        log "Vips::VipsImage::Struct.new: #{ptr}"
        super
      end
    end

    class ManagedStruct < VipsObject::ManagedStruct
      include VipsImageLayout

      def initialize(ptr)
        log "Vips::VipsImage::ManagedStruct.new: #{ptr}"
        super
      end
    end

    def self.new_partial
      VipsImage.new(Vips.vips_image_new)
    end
  end

  attach_function :vips_image_new, [], :pointer
end

puts "creating image"

x = Vips::VipsImage.new_partial
puts "x = #{x}"
puts ""
puts "x[:parent] = #{x[:parent]}"
puts ""
puts "x[:parent][:description] = #{x[:parent][:description]}"
puts ""
