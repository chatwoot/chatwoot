require "rails/generators/sass_scaffold"

module Sass
  module Generators
    class ScaffoldGenerator < ::Sass::Generators::ScaffoldBase
      def syntax() :sass end
    end
  end
end
