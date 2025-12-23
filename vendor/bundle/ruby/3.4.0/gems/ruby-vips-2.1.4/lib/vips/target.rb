# This module provides an interface to the top level bits of libvips
# via ruby-ffi.
#
# Author::    John Cupitt  (mailto:jcupitt@gmail.com)
# License::   MIT

require "ffi"

module Vips
  if Vips.at_least_libvips?(8, 9)
    attach_function :vips_target_new_to_descriptor, [:int], :pointer
    attach_function :vips_target_new_to_file, [:string], :pointer
    attach_function :vips_target_new_to_memory, [], :pointer
  end

  # A target. For example:
  #
  # ```ruby
  # target = Vips::Target.new_to_file('k2.jpg')
  # image.write_to_target(target, '.jpg')
  # ```
  class Target < Vips::Connection
    # The layout of the VipsRegion struct.
    module TargetLayout
      def self.included(base)
        base.class_eval do
          layout :parent, Vips::Connection::Struct
          # rest opaque
        end
      end
    end

    class Struct < Vips::Connection::Struct
      include TargetLayout
    end

    class ManagedStruct < Vips::Connection::ManagedStruct
      include TargetLayout
    end

    # Create a new target to a file descriptor. File descriptors are
    # small integers, for example 1 is stdout.
    #
    # Pass targets to {Image#write_to_target} to write images to
    # them.
    #
    # @param descriptor [Integer] the file descriptor
    # @return [Target] the new Vips::Target
    def self.new_to_descriptor(descriptor)
      ptr = Vips.vips_target_new_to_descriptor descriptor
      raise Vips::Error if ptr.null?

      Vips::Target.new ptr
    end

    # Create a new target to a file name.
    #
    # Pass targets to {Image#write_to_target} to write images to
    # them.
    #
    # @param filename [String] the name of the file
    # @return [Target] the new Vips::Target
    def self.new_to_file(filename)
      raise Vips::Error, "filename is nil" if filename.nil?
      ptr = Vips.vips_target_new_to_file filename
      raise Vips::Error if ptr.null?

      Vips::Target.new ptr
    end

    # Create a new target to an area of memory.
    #
    # Pass targets to {Image#write_to_target} to write images to
    # them.
    #
    # Once the image has been written, use {Object#get}`("blob")` to read out
    # the data.
    #
    # @return [Target] the new Vips::Target
    def self.new_to_memory
      ptr = Vips.vips_target_new_to_memory

      Vips::Target.new ptr
    end
  end
end
