require "rails/generators/sass_scaffold"

module Scss
  module Generators
    class ScaffoldGenerator < ::Sass::Generators::ScaffoldBase
      def syntax() :scss end
    end
  end
end

