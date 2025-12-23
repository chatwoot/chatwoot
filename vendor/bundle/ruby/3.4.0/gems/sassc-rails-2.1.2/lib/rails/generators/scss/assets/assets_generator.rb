require "rails/generators/named_base"

module Scss
  module Generators
    class AssetsGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("../templates", __FILE__)

      def copy_scss
        template "stylesheet.scss", File.join('app/assets/stylesheets', class_path, "#{file_name}.scss")
      end
    end
  end
end
