require "administrate/view_generator"

module Administrate
  module Generators
    module Views
      class NavigationGenerator < Administrate::ViewGenerator
        source_root template_source_path

        def copy_navigation
          copy_resource_template("_navigation")
        end
      end
    end
  end
end
