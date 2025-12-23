require "rails/generators/named_base"

module Sass
  module Generators
    class AssetsGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("../templates", __FILE__)

      def copy_sass
        template "stylesheet.sass", File.join('app/assets/stylesheets', class_path, "#{file_name}.sass")
      end
    end
  end
end
