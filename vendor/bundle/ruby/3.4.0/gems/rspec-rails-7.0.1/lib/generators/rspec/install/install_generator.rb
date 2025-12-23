require "rspec/support"
require "rspec/core"
RSpec::Support.require_rspec_core "project_initializer"
require "rspec/rails/feature_check"

module Rspec
  module Generators
    # @private
    class InstallGenerator < ::Rails::Generators::Base
      desc <<DESC
Description:
    Copy rspec files to your application.
DESC

      class_option :default_path, type: :string, default: 'spec'

      def self.source_root
        @source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      end

      def copy_spec_files
        Dir.mktmpdir do |dir|
          generate_rspec_init dir
          template File.join(dir, '.rspec'), '.rspec'
          directory File.join(dir, 'spec'), default_path
        end
      end

      def copy_rails_files
        template 'spec/rails_helper.rb', "#{default_path}/rails_helper.rb"
      end

    private

      def generate_rspec_init(tmpdir)
        initializer = ::RSpec::Core::ProjectInitializer.new(
          destination: tmpdir,
          report_stream: StringIO.new
        )
        initializer.run

        spec_helper_path = File.join(tmpdir, 'spec', 'spec_helper.rb')

        replace_generator_command(spec_helper_path)
        remove_warnings_configuration(spec_helper_path)

        unless default_path == "spec"
          dot_rspec_path = File.join(tmpdir, '.rspec')

          append_default_path(dot_rspec_path)
        end
      end

      def replace_generator_command(spec_helper_path)
        gsub_file spec_helper_path,
                  'rspec --init',
                  'rails generate rspec:install',
                  verbose: false
      end

      def remove_warnings_configuration(spec_helper_path)
        empty_line = '^\n'
        comment_line = '^\s*#.+\n'
        gsub_file spec_helper_path,
                  /#{empty_line}(#{comment_line})+\s+config\.warnings = true\n/,
                  '',
                  verbose: false
      end

      def append_default_path(dot_rspec_path)
        append_to_file dot_rspec_path,
                       "--default-path #{default_path}"
      end

      def default_path
        options[:default_path]
      end
    end
  end
end
