# This module provides an interface to the top level bits of libvips
# via ruby-ffi.
#
# Author::    John Cupitt  (mailto:jcupitt@gmail.com)
# License::   MIT

require "ffi"

module Vips
  if Vips.at_least_libvips?(8, 9)
    attach_function :vips_source_new_from_descriptor, [:int], :pointer
    attach_function :vips_source_new_from_file, [:pointer], :pointer
    attach_function :vips_source_new_from_memory, [:pointer, :size_t], :pointer
  end

  # A source. For example:
  #
  # ```ruby
  # source = Vips::Source.new_from_file("k2.jpg")
  # image = Vips::Image.new_from_source(source)
  # ```
  class Source < Vips::Connection
    module SourceLayout
      def self.included(base)
        base.class_eval do
          layout :parent, Vips::Connection::Struct
          # rest opaque
        end
      end
    end

    class Struct < Vips::Connection::Struct
      include SourceLayout
    end

    class ManagedStruct < Vips::Connection::ManagedStruct
      include SourceLayout
    end

    # Create a new source from a file descriptor. File descriptors are
    # small integers, for example 0 is stdin.
    #
    # Pass sources to {Image.new_from_source} to load images from
    # them.
    #
    # @param descriptor [Integer] the file descriptor
    # @return [Source] the new Vips::Source
    def self.new_from_descriptor(descriptor)
      ptr = Vips.vips_source_new_from_descriptor descriptor
      raise Vips::Error if ptr.null?

      Vips::Source.new ptr
    end

    # Create a new source from a file name.
    #
    # Pass sources to {Image.new_from_source} to load images from
    # them.
    #
    # @param filename [String] the name of the file
    # @return [Source] the new Vips::Source
    def self.new_from_file(filename)
      raise Vips::Error, "filename is nil" if filename.nil?
      ptr = Vips.vips_source_new_from_file filename
      raise Vips::Error if ptr.null?

      Vips::Source.new ptr
    end

    # Create a new source from an area of memory. Memory areas can be
    # strings, arrays and so forth -- anything that supports bytesize.
    #
    # Pass sources to {Image.new_from_source} to load images from
    # them.
    #
    # @param data [String] memory area
    # @return [Source] the new Vips::Source
    def self.new_from_memory(data)
      ptr = Vips.vips_source_new_from_memory data, data.bytesize
      raise Vips::Error if ptr.null?

      # FIXME do we need to keep a ref to the underlying memory area? what
      # about Image.new_from_buffer? Does that need a secret ref too?

      Vips::Source.new ptr
    end
  end
end
