require "administrate/view_generator"

module Administrate
  module Generators
    module Views
      class LayoutGenerator < Administrate::ViewGenerator
        source_root template_source_path

        def copy_template
          copy_file(
            "../../layouts/administrate/application.html.erb",
            "app/views/layouts/admin/application.html.erb",
          )

          call_generator("administrate:views:navigation")
          copy_resource_template("_stylesheet")
          copy_resource_template("_javascript")
          copy_resource_template("_flashes")
          copy_resource_template("_icons")
        end
      end
    end
  end
end
