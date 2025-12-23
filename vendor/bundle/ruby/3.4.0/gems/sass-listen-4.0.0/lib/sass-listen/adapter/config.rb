require 'pathname'

module SassListen
  module Adapter
    class Config
      attr_reader :directories
      attr_reader :silencer
      attr_reader :queue
      attr_reader :adapter_options

      def initialize(directories, queue, silencer, adapter_options)
        # Default to current directory if no directories are supplied
        directories = [Dir.pwd] if directories.to_a.empty?
        
        # TODO: fix (flatten, array, compact?)
        @directories = directories.map do |directory|
          Pathname.new(directory.to_s).realpath
        end

        @silencer = silencer
        @queue = queue
        @adapter_options = adapter_options
      end
    end
  end
end
