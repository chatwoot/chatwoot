# frozen_string_literal: true

require_relative 'file_finder'

module RuboCop
  # This class has methods related to finding configuration path.
  # @api private
  class ConfigFinder
    DOTFILE = '.rubocop.yml'
    XDG_CONFIG = 'config.yml'
    RUBOCOP_HOME = File.realpath(File.join(File.dirname(__FILE__), '..', '..'))
    DEFAULT_FILE = File.join(RUBOCOP_HOME, 'config', 'default.yml')

    class << self
      include FileFinder

      attr_writer :project_root

      def find_config_path(target_dir)
        find_project_dotfile(target_dir) || find_project_root_dot_config ||
          find_user_dotfile || find_user_xdg_config || DEFAULT_FILE
      end

      # Returns the path RuboCop inferred as the root of the project. No file
      # searches will go past this directory.
      def project_root
        @project_root ||= find_project_root
      end

      private

      def find_project_root
        pwd = Dir.pwd
        gems_file = find_last_file_upwards('Gemfile', pwd) || find_last_file_upwards('gems.rb', pwd)
        return unless gems_file

        File.dirname(gems_file)
      end

      def find_project_dotfile(target_dir)
        find_file_upwards(DOTFILE, target_dir, project_root)
      end

      def find_project_root_dot_config
        return unless project_root

        dotfile = File.join(project_root, '.config', DOTFILE)
        return dotfile if File.exist?(dotfile)

        xdg_config = File.join(project_root, '.config', 'rubocop', XDG_CONFIG)
        xdg_config if File.exist?(xdg_config)
      end

      def find_user_dotfile
        return unless ENV.key?('HOME')

        file = File.join(Dir.home, DOTFILE)

        file if File.exist?(file)
      end

      def find_user_xdg_config
        xdg_config_home = expand_path(ENV.fetch('XDG_CONFIG_HOME', '~/.config'))
        xdg_config = File.join(xdg_config_home, 'rubocop', XDG_CONFIG)

        xdg_config if File.exist?(xdg_config)
      end

      def expand_path(path)
        File.expand_path(path)
      rescue ArgumentError
        # Could happen because HOME or ID could not be determined. Fall back on
        # using the path literally in that case.
        path
      end
    end
  end
end
