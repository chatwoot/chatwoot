# frozen_string_literal: true

module Byebug
  module Helpers
    #
    # Utilities for interaction with executables
    #
    module BinHelper
      #
      # Cross-platform way of finding an executable in the $PATH.
      # Adapted from: https://gist.github.com/steakknife/88b6c3837a5e90a08296
      #
      def which(cmd)
        return File.expand_path(cmd) if File.exist?(cmd)

        [nil, *search_paths].each do |path|
          exe = find_executable(path, cmd)
          return exe if exe
        end

        nil
      end

      def find_executable(path, cmd)
        executable_file_extensions.each do |ext|
          exe = File.expand_path(cmd + ext, path)

          return exe if real_executable?(exe)
        end

        nil
      end

      def search_paths
        ENV["PATH"].split(File::PATH_SEPARATOR)
      end

      def executable_file_extensions
        ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]
      end

      def real_executable?(file)
        File.executable?(file) && !File.directory?(file)
      end
    end
  end
end
