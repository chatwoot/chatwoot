# This module provides an interface to the top level bits of libvips
# via ruby-ffi.
#
# Author::    John Cupitt  (mailto:jcupitt@gmail.com)
# License::   MIT

require "ffi"

module Vips
  if Vips.at_least_libvips?(8, 9)
    attach_function :vips_target_custom_new, [], :pointer
  end

  # A target you can attach action signal handlers to to implememt
  # custom output types.
  #
  # For example:
  #
  # ```ruby
  # file = File.open "some/file/name", "wb"
  # target = Vips::TargetCustom.new
  # target.on_write { |bytes| file.write bytes }
  # image.write_to_target target, ".png"
  # ```
  #
  # (just an example -- of course in practice you'd use {Target#new_to_file}
  # to write to a named file)
  class TargetCustom < Vips::Target
    module TargetCustomLayout
      def self.included(base)
        base.class_eval do
          layout :parent, Vips::Target::Struct
          # rest opaque
        end
      end
    end

    class Struct < Vips::Target::Struct
      include TargetCustomLayout
    end

    class ManagedStruct < Vips::Target::ManagedStruct
      include TargetCustomLayout
    end

    def initialize
      pointer = Vips.vips_target_custom_new
      raise Vips::Error if pointer.null?

      super pointer
    end

    # The block is executed to write data to the source. The interface is
    # exactly as IO::write, ie. it should write the string and return the
    # number of bytes written.
    #
    # @yieldparam bytes [String] Write these bytes to the file
    # @yieldreturn [Integer] The number of bytes written, or -1 on error
    def on_write &block
      signal_connect "write" do |p, len|
        chunk = p.get_bytes(0, len)
        bytes_written = block.call chunk
        chunk.clear

        bytes_written
      end
    end

    # The block is executed at the end of write. It should do any necessary
    # finishing action, such as closing a file.
    def on_finish &block
      signal_connect "finish" do
        block.call
      end
    end
  end
end
