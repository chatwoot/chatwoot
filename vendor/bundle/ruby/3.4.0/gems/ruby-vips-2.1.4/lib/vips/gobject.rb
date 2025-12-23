# This module provides an interface to the top level bits of GObject
# via ruby-ffi.
#
# Author::    John Cupitt  (mailto:jcupitt@gmail.com)
# License::   MIT

require "ffi"
require "forwardable"

module GObject
  # we have a number of things we need to inherit in different ways:
  #
  # - we want to be able to subclass GObject in Ruby in a simple way
  # - the layouts of the nested structs need to inherit
  # - we need to be able to cast between structs which share a base struct
  #   without creating new wrappers or messing up refcounting
  # - we need automatic gobject refcounting
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

    attr_reader :references

    # the layout of the GObject struct
    module GObjectLayout
      def self.included base
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

      def self.release ptr
        # GLib::logger.debug("GObject::GObject::ManagedStruct.release") {
        #     "unreffing #{ptr}"
        # }
        ::GObject.g_object_unref ptr
      end
    end

    # the plain struct ... cast with this
    class Struct < FFI::Struct
      include GObjectLayout
    end

    # don't allow ptr == nil, we never want to allocate a GObject struct
    # ourselves, we just want to wrap GLib-allocated GObjects
    #
    # here we use ManagedStruct, not Struct, since this is the ref that will
    # need the unref
    def initialize ptr
      # GLib::logger.debug("GObject::GObject.initialize") {"ptr = #{ptr}"}
      @ptr = ptr
      @struct = ffi_managed_struct.new ptr

      # sometimes we need to keep refs across C calls ... hide them here
      @references = []
    end

    # access to the casting struct for this class
    def ffi_struct
      self.class.ffi_struct
    end

    # get the pointer we were built from ... #to_ptr gets the pointer after we
    # have wrapped it up with an auto unref
    attr_reader :ptr

    class << self
      def ffi_struct
        const_get :Struct
      end
    end

    # access to the managed struct for this class
    def ffi_managed_struct
      self.class.ffi_managed_struct
    end

    class << self
      def ffi_managed_struct
        const_get :ManagedStruct
      end
    end
  end

  class GParamSpec < FFI::Struct
    # the first few public fields
    layout :g_type_instance, :pointer,
      :name, :string,
      :flags, :uint,
      :value_type, :GType,
      :owner_type, :GType
  end

  class GParamSpecPtr < FFI::Struct
    layout :value, GParamSpec.ptr
  end

  attach_function :g_param_spec_get_blurb, [:pointer], :string

  attach_function :g_object_ref, [:pointer], :void
  attach_function :g_object_unref, [:pointer], :void

  # we just use one gcallback type for every signal, hopefully this is OK
  callback :gcallback, [:pointer], :void
  attach_function :g_signal_connect_data,
    [:pointer, :string, :gcallback, :pointer, :pointer, :int], :long
end
