# frozen_string_literal: true

module Byebug
  module Helpers
    #
    # Utilities for managing gem paths
    #
    module PathHelper
      def bin_file
        @bin_file ||= File.join(root_path, "exe", "byebug")
      end

      def root_path
        @root_path ||= File.expand_path(File.join("..", "..", ".."), __dir__)
      end

      def lib_files
        @lib_files ||= glob_for("lib")
      end

      def test_files
        @test_files ||= glob_for("test")
      end

      def gem_files
        @gem_files ||= [bin_file] + lib_files
      end

      def all_files
        @all_files ||= gem_files + test_files
      end

      private

      def glob_for(dir)
        Dir.glob(File.join(root_path, dir, "**", "*.rb"))
      end
    end
  end
end
