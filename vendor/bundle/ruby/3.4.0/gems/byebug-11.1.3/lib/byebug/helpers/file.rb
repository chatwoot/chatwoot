# frozen_string_literal: true

module Byebug
  module Helpers
    #
    # Utilities for interaction with files
    #
    module FileHelper
      #
      # Reads lines of source file +filename+ into an array
      #
      def get_lines(filename)
        File.foreach(filename).reduce([]) { |acc, elem| acc << elem.chomp }
      end

      #
      # Reads line number +lineno+ from file named +filename+
      #
      def get_line(filename, lineno)
        File.open(filename) do |f|
          f.gets until f.lineno == lineno - 1
          f.gets
        end
      end

      #
      # Returns the number of lines in file +filename+ in a portable,
      # one-line-at-a-time way.
      #
      def n_lines(filename)
        File.foreach(filename).reduce(0) { |acc, _elem| acc + 1 }
      end

      #
      # Regularize file name.
      #
      def normalize(filename)
        return filename if virtual_file?(filename)

        return File.basename(filename) if Setting[:basename]

        File.exist?(filename) ? File.realpath(filename) : filename
      end

      #
      # A short version of a long path
      #
      def shortpath(fullpath)
        components = Pathname(fullpath).each_filename.to_a
        return fullpath if components.size <= 2

        File.join("...", components[-3..-1])
      end

      #
      # True for special files like -e, false otherwise
      #
      def virtual_file?(name)
        ["(irb)", "-e", "(byebug)", "(eval)"].include?(name)
      end
    end
  end
end
