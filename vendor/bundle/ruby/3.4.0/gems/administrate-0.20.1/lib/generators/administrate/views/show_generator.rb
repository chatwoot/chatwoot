require "administrate/view_generator"

module Administrate
  module Generators
    module Views
      class ShowGenerator < Administrate::ViewGenerator
        source_root template_source_path

        def copy_template
          copy_resource_template("show")
        end
      end
    end
  end
end
