require 'pathname'
require 'ffi'
require_relative 'platform'

module FFI
  module Compiler
    module Loader
      def self.find(name, start_path = nil)
        library = Platform.system.map_library_name(name)
        root = false
        Pathname.new(start_path || caller_path(caller[0])).ascend do |path|
          Dir.glob("#{path}/**/{#{FFI::Platform::ARCH}-#{FFI::Platform::OS}/#{library},#{library}}") do |f|
            return f
          end

          break if root

          # Next iteration will be the root of the gem if this is the lib/ dir - stop after that
          root = File.basename(path) == 'lib'
        end
        raise LoadError.new("cannot find '#{name}' library")
      end

      def self.caller_path(line = caller[0])
        if FFI::Platform::OS == 'windows'
          drive = line[0..1]
          path =  line[2..-1].split(/:/)[0]
          full_path = drive + path
        else
          full_path = line.split(/:/)[0]
        end
        File.dirname full_path
      end
    end
  end
end