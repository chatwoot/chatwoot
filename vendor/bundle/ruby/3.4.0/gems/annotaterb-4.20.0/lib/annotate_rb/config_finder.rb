# frozen_string_literal: true

module AnnotateRb
  class ConfigFinder
    DOTFILE = ".annotaterb.yml"

    class << self
      def find_project_root
        # We should expect this method to be called from a Rails project root and returning it
        # e.g. "/Users/drwl/personal/annotaterb/dummyapp"
        Dir.pwd
      end

      def find_project_dotfile
        file_path = File.expand_path(DOTFILE, find_project_root)

        return file_path if File.exist?(file_path)
      end
    end
  end
end
