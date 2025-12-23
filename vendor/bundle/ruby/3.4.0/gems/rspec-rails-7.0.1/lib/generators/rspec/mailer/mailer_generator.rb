require 'generators/rspec'
require "rspec/rails/feature_check"

module Rspec
  module Generators
    # @private
    class MailerGenerator < Base
      argument :actions, type: :array, default: [], banner: "method method"

      def generate_mailer_spec
        file_suffix = file_name.end_with?('mailer') ? 'spec.rb' : 'mailer_spec.rb'
        template "mailer_spec.rb", target_path('mailers', class_path, [file_name, file_suffix].join('_'))
      end

      def generate_fixtures_files
        actions.each do |action|
          @action, @path = action, File.join(file_path, action)
          template "fixture", target_path("fixtures", @path)
        end
      end

      def generate_preview_files
        return unless RSpec::Rails::FeatureCheck.has_action_mailer_preview?

        file_suffix = file_name.end_with?('mailer') ? 'preview.rb' : 'mailer_preview.rb'
        template "preview.rb", target_path("mailers/previews", class_path, [file_name, file_suffix].join('_'))
      end
    end
  end
end
