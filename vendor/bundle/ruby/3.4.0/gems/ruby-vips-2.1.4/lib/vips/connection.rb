# This module provides an interface to the top level bits of libvips
# via ruby-ffi.
#
# Author::    John Cupitt  (mailto:jcupitt@gmail.com)
# License::   MIT

require "ffi"

module Vips
  if Vips.at_least_libvips?(8, 9)
    attach_function :vips_connection_filename, [:pointer], :string
    attach_function :vips_connection_nick, [:pointer], :string
  end

  # Abstract base class for connections.
  class Connection < Vips::Object
    # The layout of the VipsRegion struct.
    module ConnectionLayout
      def self.included(base)
        base.class_eval do
          layout :parent, Vips::Object::Struct
          # rest opaque
        end
      end
    end

    class Struct < Vips::Object::Struct
      include ConnectionLayout
    end

    class ManagedStruct < Vips::Object::ManagedStruct
      include ConnectionLayout
    end

    # Get any filename associated with a connection, or nil.
    def filename
      Vips.vips_connection_filename self
    end

    # Get a nickname (short description) of a connection that could be shown to
    # the user.
    def nick
      Vips.vips_connection_nick self
    end
  end
end
